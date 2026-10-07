//
//  RewardedAdManager.swift
//  StockWarChronicles
//

import Combine
import GoogleMobileAds

enum RewardedAdOutcome {
    case rewarded
    case dismissed
    case failed
}

final class RewardedAdManager: NSObject, ObservableObject {
    @Published private(set) var isAdReady = false

    private var rewardedAd: RewardedAd?
    private var presentingAd: RewardedAd?
    private var isLoading = false
    private var didEarnReward = false
    private var completion: ((RewardedAdOutcome) -> Void)?

    func loadAd() async {
        guard rewardedAd == nil, !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let ad = try await RewardedAd.load(
                with: AdMobConfiguration.rewardedAdUnitID,
                request: Request()
            )
            ad.fullScreenContentDelegate = self
            rewardedAd = ad
            isAdReady = true
        } catch {
            rewardedAd = nil
            isAdReady = false
#if DEBUG
            print("Rewarded ad failed to load: \(error.localizedDescription)")
#endif
        }
    }

    func prepareAd() async -> Bool {
        if isAdReady { return true }

        await loadAd()

        // If an app-launch preload is still running, wait briefly for it to finish.
        for _ in 0..<100 where !isAdReady && isLoading {
            try? await Task.sleep(for: .milliseconds(100))
        }

        return isAdReady
    }

    @discardableResult
    func present(completion: @escaping (RewardedAdOutcome) -> Void) -> Bool {
        guard let rewardedAd else { return false }

        self.completion = completion
        didEarnReward = false
        self.rewardedAd = nil
        presentingAd = rewardedAd
        isAdReady = false

        rewardedAd.present(from: nil) { [weak self] in
            self?.didEarnReward = true
        }

        // Rewarded ads are single-use. Preload the next one while this ad is being shown.
        Task {
            await loadAd()
        }
        return true
    }

    private func finish(with outcome: RewardedAdOutcome) {
        presentingAd = nil

        let completion = completion
        self.completion = nil
        completion?(outcome)

        if rewardedAd == nil {
            isAdReady = false
            Task {
                await loadAd()
            }
        }
    }
}

extension RewardedAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        finish(with: didEarnReward ? .rewarded : .dismissed)
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
#if DEBUG
        print("Rewarded ad failed to present: \(error.localizedDescription)")
#endif
        finish(with: .failed)
    }
}
