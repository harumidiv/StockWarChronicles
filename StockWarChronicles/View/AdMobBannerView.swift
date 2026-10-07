//
//  AdMobBannerView.swift
//  StockWarChronicles
//

import GoogleMobileAds
import SwiftUI

struct AdMobBannerView: View {
    @State private var availableWidth: CGFloat = 0
    @State private var isAdLoaded = false

    var body: some View {
        Group {
            if availableWidth > 0 {
                let adSize = largeAnchoredAdaptiveBanner(width: availableWidth)

                BannerViewContainer(
                    adSize: adSize,
                    adUnitID: AdMobConfiguration.bannerAdUnitID,
                    isAdLoaded: $isAdLoaded
                )
                .frame(width: adSize.size.width, height: adSize.size.height)
                .frame(height: isAdLoaded ? adSize.size.height : 0, alignment: .bottom)
                .clipped()
                .animation(.easeOut(duration: 0.2), value: isAdLoaded)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            availableWidth = newWidth
        }
    }
}

private enum AdMobConfiguration {
    static var bannerAdUnitID: String {
#if DEBUG
        // Google-provided iOS banner test ad unit ID.
        return "ca-app-pub-3940256099942544/2435281174"
#else
        return "ca-app-pub-8522231452310619/6089502791"
#endif
    }
}

private struct BannerViewContainer: UIViewRepresentable {
    let adSize: AdSize
    let adUnitID: String
    @Binding var isAdLoaded: Bool

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: adSize)
        bannerView.adUnitID = adUnitID
        bannerView.delegate = context.coordinator
        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(isAdLoaded: $isAdLoaded)
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        @Binding private var isAdLoaded: Bool

        init(isAdLoaded: Binding<Bool>) {
            _isAdLoaded = isAdLoaded
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            isAdLoaded = true
        }

        func bannerView(
            _ bannerView: BannerView,
            didFailToReceiveAdWithError error: Error
        ) {
            isAdLoaded = false
#if DEBUG
            print("Banner ad failed to load: \(error.localizedDescription)")
#endif
        }
    }
}

#if DEBUG
#Preview {
    AdMobBannerView()
}
#endif
