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
    @State private var adviceText: String = ""
    @State private var isLoading: Bool = false

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
            isLoading = true
            do {
                let session = LanguageModelSession(instructions: instructions)
                let response = try await session.respond(to: prompt)
                adviceText = response.content
            } catch {
                adviceText = "AIとのコミュニケーションに失敗しました。"
            }
            isLoading = false
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
}
