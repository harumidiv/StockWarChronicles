//
//  Color+.swift
//  StockWarChronicles
//
//  Created by 佐川 晴海 on 2025/09/04.
//

import SwiftUI

extension Color {
    func isLight() -> Bool {
        // SwiftUIのColorをUIColorに変換
        let uiColor = UIColor(self)
        
        // UIColorからRGBA成分を取得
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // 輝度（Luminance）を計算
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        
        // 輝度が特定のしきい値（例: 0.5）より高ければ明るい色と判定
        return luminance > 0.5
    }
    
    static func randomPastel() -> Color {
        // HSB（Hue, Saturation, Brightness）モデルを使用
        // 色相（Hue）: 0.0〜1.0 の間で完全にランダムに選択（色を決定）
        let hue = Double.random(in: 0...1)
        
        // 彩度（Saturation）: 0.4〜0.6 の間で選択（鮮やかさを調整）
        let saturation = Double.random(in: 0.4...0.7)
        
        // 明度（Brightness）: 0.8〜0.9 の間で選択（薄さを調整）
        let brightness = Double.random(in: 0.8...0.9)
        
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
}
