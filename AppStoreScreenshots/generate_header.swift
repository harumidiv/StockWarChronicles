// README・App Store 用のヘッダー画像を、Simulator で撮った画面（raw-duo）から作る
// usage: swift AppStoreScreenshots/generate_header.swift
import AppKit

// swift で直接実行すると #filePath がモジュール名になるため、引数の0番目（このファイルのパス）から求める
let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let raw = root.appendingPathComponent("raw-duo")
let appIcon = root.deletingLastPathComponent()
    .appendingPathComponent("StockWarChronicles/Recource/Assets.xcassets/AppIcon.appiconset/icon2.png")

// 2560x1280（GitHub のソーシャルプレビュー 1280x640 の2倍）を基準にレイアウトし、各サイズへ拡大する
let baseWidth: CGFloat = 2560
let baseHeight: CGFloat = 1280
let outputs: [(String, Int, Int)] = [
    ("header.png", 2560, 1280),
    ("header_appstore_5244x2950.png", 5244, 2950),
    ("header_appstore_3840x1646.png", 3840, 1646),
]

// アプリアイコンに合わせた色
func rgb(_ r: Int, _ g: Int, _ b: Int, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: a)
}
let navy = rgb(28, 48, 74)
let secondary = rgb(78, 90, 104)
let cream = rgb(253, 246, 228)
let yellow = rgb(255, 214, 92)
let red = rgb(240, 78, 52)
let green = rgb(46, 178, 94)
let blue = rgb(40, 120, 220)

func loadCG(_ url: URL) -> CGImage {
    let rep = NSBitmapImageRep(data: try! Data(contentsOf: url))!
    return rep.cgImage!
}

func roundedPath(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

for (name, width, height) in outputs {
    let cg = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                       space: CGColorSpace(name: CGColorSpace.sRGB)!,
                       bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    // 左上原点で描く
    cg.translateBy(x: 0, y: CGFloat(height))
    cg.scaleBy(x: 1, y: -1)
    // 基準サイズが収まるように拡大し、余った幅・高さ（extraX, extraY）は要素の間隔に回す
    let scale = min(CGFloat(width) / baseWidth, CGFloat(height) / baseHeight)
    cg.scaleBy(x: scale, y: scale)
    let canvasWidth = CGFloat(width) / scale
    let canvasHeight = CGFloat(height) / scale
    let extraX = canvasWidth - baseWidth
    let extraY = canvasHeight - baseHeight
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)

    NSGradient(starting: yellow, ending: cream)!.draw(in: CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight), angle: 135)
    let circles: [(CGRect, NSColor)] = [
        (CGRect(x: -180, y: -200, width: 520, height: 520), rgb(255, 255, 255, 0.45)),
        (CGRect(x: 2250, y: -160, width: 480, height: 480), red.withAlphaComponent(0.35)),
        (CGRect(x: 1180, y: 960, width: 420, height: 420), green.withAlphaComponent(0.3)),
        (CGRect(x: 2330, y: 900, width: 360, height: 360), blue.withAlphaComponent(0.25)),
        (CGRect(x: 1060, y: 110, width: 120, height: 120), rgb(255, 255, 255, 0.6)),
    ]
    for (rect, color) in circles {
        color.setFill()
        // 位置だけキャンバスに合わせて伸ばす
        let moved = CGRect(x: rect.minX * canvasWidth / baseWidth, y: rect.minY * canvasHeight / baseHeight,
                           width: rect.width, height: rect.height)
        NSBezierPath(ovalIn: moved).fill()
    }

    // 左側：アイコン・アプリ名・キャッチコピー
    let left: CGFloat = 150 + extraX * 0.25
    let middle = extraY / 2
    let icon = loadCG(appIcon)
    let iconRect = CGRect(x: left, y: 250 + middle, width: 220, height: 220)
    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: 16), blur: 40, color: rgb(22, 36, 52, 0.25).cgColor)
    cg.addPath(roundedPath(iconRect, 50))
    cg.setFillColor(NSColor.white.cgColor)
    cg.fillPath()
    cg.restoreGState()
    cg.saveGState()
    cg.addPath(roundedPath(iconRect, 50))
    cg.clip()
    // CGImage は下から描かれるため、反転を打ち消して置く
    cg.translateBy(x: 0, y: iconRect.maxY + iconRect.minY)
    cg.scaleBy(x: 1, y: -1)
    cg.draw(icon, in: iconRect)
    cg.restoreGState()

    NSAttributedString(string: "かぶ戦記", attributes: [
        .font: NSFont(name: "HiraginoSans-W8", size: 200)!, .foregroundColor: navy, .kern: 10,
    ]).draw(at: CGPoint(x: left - 8, y: 510 + middle))
    NSAttributedString(string: "日本株トレードノートアプリ", attributes: [
        .font: NSFont(name: "HiraginoSans-W6", size: 68)!, .foregroundColor: secondary, .kern: 4,
    ]).draw(at: CGPoint(x: left, y: 770 + middle))

    // キャッチコピーは帯の上に載せる
    let catchText = NSAttributedString(string: "なんとなくの取引から卒業", attributes: [
        .font: NSFont(name: "HiraginoSans-W7", size: 64)!, .foregroundColor: NSColor.white, .kern: 2,
    ])
    let catchSize = catchText.size()
    let pill = CGRect(x: left, y: 910 + middle, width: catchSize.width + 100, height: catchSize.height + 50)
    cg.addPath(roundedPath(pill, pill.height / 2))
    cg.setFillColor(red.cgColor)
    cg.fillPath()
    catchText.draw(at: CGPoint(x: pill.minX + 50, y: pill.minY + 25))

    // 右側：画面を3枚、下にはみ出すように並べる（下端・右寄せで揃える）
    let screenHeight: CGFloat = 1020
    let screenRadius: CGFloat = 44
    let screens: [(String, CGFloat, CGFloat)] = [
        ("history.png", 1580, 300),
        ("performance.png", 2200, 300),
        ("list.png", 1890, 190),
    ]
    for (name, centerX, top) in screens {
        let screen = loadCG(raw.appendingPathComponent(name))
        let screenWidth = screenHeight * CGFloat(screen.width) / CGFloat(screen.height)
        let screenRect = CGRect(x: centerX + extraX * 0.75 - screenWidth / 2, y: top + extraY, width: screenWidth, height: screenHeight)
        let frameRect = screenRect.insetBy(dx: -12, dy: -12)
        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: 20), blur: 60, color: rgb(22, 36, 52, 0.3).cgColor)
        cg.addPath(roundedPath(frameRect, screenRadius + 12))
        cg.setFillColor(NSColor.white.cgColor)
        cg.fillPath()
        cg.restoreGState()
        cg.saveGState()
        cg.addPath(roundedPath(screenRect, screenRadius))
        cg.clip()
        cg.translateBy(x: 0, y: screenRect.maxY + screenRect.minY)
        cg.scaleBy(x: 1, y: -1)
        cg.interpolationQuality = .high
        cg.draw(screen, in: screenRect)
        cg.restoreGState()
    }

    NSGraphicsContext.current = nil
    let out = root.appendingPathComponent(name)
    try! NSBitmapImageRep(cgImage: cg.makeImage()!).representation(using: .png, properties: [:])!.write(to: out)
    print(out.path)
}
