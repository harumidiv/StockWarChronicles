//
//  AdviceView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/10/09.
//

import SwiftUI
import FoundationModels

struct AdviceView: View {
    let navigationTitle: String
    let instructions: String
    let prompt: String

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var rewardedAdManager: RewardedAdManager

    @State private var adviceText: String = ""
    @State private var isLoading: Bool = false
    @State private var hasStarted = false
    @State private var showAdUnavailableAlert = false

    var body: some View {
        Group {
            VStack {
                HStack(alignment: .center) {
                    Text("AIからのアドバイス")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    Spacer()
                    Image(systemName: "brain.head.profile")
                        .resizable()
                        .frame(width: 50, height: 50)
                }
                .padding(.horizontal) // Apply horizontal padding to the HStack
                
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(2)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(adviceText)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle(navigationTitle)
        .task {
            await startAnalysis()
        }
        .alert("広告を表示できません", isPresented: $showAdUnavailableAlert) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("通信状態を確認して、少し待ってからもう一度お試しください。")
        }
    }

    private func startAnalysis() async {
        guard !hasStarted else { return }

        hasStarted = true
        isLoading = true

        // Start generating before the ad appears so the result can be prepared
        // while the user is watching it.
        let analysisTask = Task {
            await generateAdvice()
        }
        let adPreparationTask = Task {
            await rewardedAdManager.prepareAd()
        }

        // Let the navigation transition finish before presenting the full-screen ad.
        try? await Task.sleep(for: .milliseconds(400))

        guard !Task.isCancelled else {
            analysisTask.cancel()
            adPreparationTask.cancel()
            return
        }

        guard await adPreparationTask.value else {
            analysisTask.cancel()
            isLoading = false
            showAdUnavailableAlert = true
            return
        }

        let outcome = await presentRewardedAd()
        switch outcome {
        case .rewarded:
            adviceText = await analysisTask.value
            isLoading = false
        case .dismissed:
            analysisTask.cancel()
            dismiss()
        case .failed:
            analysisTask.cancel()
            isLoading = false
            showAdUnavailableAlert = true
        }
    }

    private func generateAdvice() async -> String {
        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(temperature: 2.0)
            )
            return response.content
        } catch {
            return "AIとのコミュニケーションに失敗しました。"
        }
    }

    private func presentRewardedAd() async -> RewardedAdOutcome {
        await withCheckedContinuation { continuation in
            let didPresent = rewardedAdManager.present { outcome in
                continuation.resume(returning: outcome)
            }

            if !didPresent {
                continuation.resume(returning: .failed)
            }
        }
    }
}

#Preview {
    let instructions = """
    あなたはプロのトレードコーチです。
    ユーザーのトレード記録と感情メモを分析し、負けた原因と今後の改善策を明確に示してください。
    感情的にならず、客観的かつ実践的に回答してください。
    出力は次の形式にしてください：
    1. どんな失敗が多かったか
    2. 改善案
    """
    AdviceView(navigationTitle: "負けトレード", instructions: instructions, prompt: "怒り:決算が思ったようにいかなかった悲しみ:損切りラインを割ったのに持ち越してしまった")
        .environmentObject(RewardedAdManager())
}
