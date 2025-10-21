//
//  ScreenshotMakerView.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/10/21.
//

import SwiftUI

/// `ScreenshotMaker`を引数とするクロージャー
typealias ScreenshotMakerClosure = (ScreenshotMaker) -> Void

/// `ScreenshotMaker`ビューのSwiftUI表現
struct ScreenshotMakerView: UIViewRepresentable {

    let closure: ScreenshotMakerClosure

    /// クロージャーを使用して`ScreenshotMakerView`を初期化します
    init(_ closure: @escaping ScreenshotMakerClosure) {
      self.closure = closure
    }

    func makeUIView(context _: Context) -> ScreenshotMaker {
        let view = ScreenshotMaker(frame: CGRect.zero)
        return view
    }

    func updateUIView(_ uiView: ScreenshotMaker, context _: Context) {
        DispatchQueue.main.async {
          closure(uiView)
        }
     }
}

extension View {
    /// ビューにスクリーンショットのオーバーレイを追加します
    /// - Parameter closure: スクリーンショットを撮る際に実行されるクロージャー
    /// - Returns: スクリーンショットのオーバーレイが追加された変更されたビュー
    func screenshotView(_ closure: @escaping ScreenshotMakerClosure) -> some View {

      let screenshotView = ScreenshotMakerView(closure)

      return overlay(screenshotView.allowsHitTesting(false))
    }
}

final class ScreenshotMaker: UIView {

    /// このビューの親の、さらに親ビューのスクリーンショットを撮ります
    /// - Returns: ビューのスクリーンショットを含むUIImage
    func screenshot() -> UIImage? {
       guard let containerView = superview?.superview,

        let containerSuperview = containerView.superview else { return nil }
        let renderer = UIGraphicsImageRenderer(bounds: containerView.frame)
        return renderer.image { context in
        containerSuperview.layer.render(in: context.cgContext)
        }
    }
}
