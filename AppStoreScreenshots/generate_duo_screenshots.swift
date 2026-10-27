// iPhone Duo 用の App Store スクリーンショットを、Simulator で撮った画面（raw-duo）から作る
// usage: swift AppStoreScreenshots/generate_duo_screenshots.swift
import AppKit

// swift で直接実行すると #filePath がモジュール名になるため、引数の0番目（このファイルのパス）から求める
let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let raw = root.appendingPathComponent("raw-duo")
let out = root.appendingPathComponent("final-duo")
let appIcon = root.deletingLastPathComponent()
    .appendingPathComponent("StockWarChronicles/Recource/Assets.xcassets/AppIcon.appiconset/icon2.png")

// iPhone Duo（開いた状態）の画面サイズ
let width = 2007
let height = 2853

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

let screenTop: CGFloat = 610
let screenHeight: CGFloat = 2150
let screenRadius: CGFloat = 72

struct Page {
    let source: String
    let output: String
    let title: String
    let subtitle: String
    let top: NSColor
    let bottom: NSColor
    let circles: [(CGRect, NSColor)]
}

let pages = [
    Page(source: "list.png", output: "01-record.png",
         title: "なんとなくの取引から卒業", subtitle: "日本株の売買を、ノートのように記録",
         top: yellow, bottom: cream,
         circles: [(CGRect(x: 1700, y: -150, width: 460, height: 460), red.withAlphaComponent(0.35)),
                   (CGRect(x: -210, y: 380, width: 360, height: 360), rgb(255, 255, 255, 0.5)),
                   (CGRect(x: 1780, y: 470, width: 280, height: 280), rgb(255, 255, 255, 0.4))]),
    Page(source: "performance.png", output: "02-performance.png",
         title: "年間の成績を自動で分析", subtitle: "損益・勝率・平均保有日数がひと目でわかる",
         top: rgb(206, 236, 214), bottom: cream,
         circles: [(CGRect(x: -220, y: -110, width: 470, height: 470), green.withAlphaComponent(0.4)),
                   (CGRect(x: 1760, y: 380, width: 400, height: 400), yellow)]),
    Page(source: "history.png", output: "03-calendar.png",
         title: "カレンダーで損益をふり返る", subtitle: "売却履歴と日々のメモを日付ごとに記録",
         top: rgb(255, 214, 200), bottom: cream,
         circles: [(CGRect(x: 1740, y: -160, width: 480, height: 480), red.withAlphaComponent(0.4)),
                   (CGRect(x: -200, y: 430, width: 370, height: 370), yellow),
                   (CGRect(x: 1820, y: 470, width: 120, height: 120), rgb(255, 255, 255, 0.6))]),
    Page(source: "map.png", output: "04-allocation.png",
         title: "保有株の配分を見える化", subtitle: "ドーナッツ・ツリーマップでシェアもできる",
         top: rgb(204, 224, 250), bottom: cream,
         circles: [(CGRect(x: -220, y: -100, width: 470, height: 470), blue.withAlphaComponent(0.3)),
                   (CGRect(x: 1770, y: 360, width: 410, height: 410), yellow)]),
]

func loadCG(_ url: URL) -> CGImage {
    let rep = NSBitmapImageRep(data: try! Data(contentsOf: url))!
    return rep.cgImage!
}

func drawCentered(_ text: String, font: NSFont, color: NSColor, y: CGFloat, maxWidth: CGFloat) {
    var font = font
    var attributed = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
    // 長い見出しは1行に収まるまで小さくする
    while attributed.size().width > maxWidth {
        font = NSFont(descriptor: font.fontDescriptor, size: font.pointSize - 4)!
        attributed = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
    }
    let size = attributed.size()
    attributed.draw(at: CGPoint(x: (CGFloat(width) - size.width) / 2, y: y))
}

func roundedPath(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func render(_ page: Page) -> URL {
    // App Store は透過を受け付けないため、最初からアルファなしのキャンバスに描く
    let cg = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                       space: CGColorSpace(name: CGColorSpace.sRGB)!,
                       bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    // 左上原点で描く
    cg.translateBy(x: 0, y: CGFloat(height))
    cg.scaleBy(x: 1, y: -1)
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)

    let gradient = NSGradient(starting: page.top, ending: page.bottom)!
    gradient.draw(in: CGRect(x: 0, y: 0, width: width, height: height), angle: 90)
    for (rect, color) in page.circles {
        color.setFill()
        NSBezierPath(ovalIn: rect).fill()
    }

    // アプリアイコンと名前
    let icon = loadCG(appIcon)
    let iconSize: CGFloat = 116
    let brand = NSAttributedString(string: "かぶ戦記", attributes: [
        .font: NSFont(name: "HiraginoSans-W8", size: 60)!, .foregroundColor: navy, .kern: 4,
    ])
    let brandWidth = iconSize + 28 + brand.size().width
    let brandX = (CGFloat(width) - brandWidth) / 2
    let iconRect = CGRect(x: brandX, y: 92, width: iconSize, height: iconSize)
    cg.saveGState()
    cg.addPath(roundedPath(iconRect, 27))
    cg.clip()
    // CGImage は下から描かれるため、反転を打ち消して置く
    cg.translateBy(x: 0, y: iconRect.maxY + iconRect.minY)
    cg.scaleBy(x: 1, y: -1)
    cg.draw(icon, in: iconRect)
    cg.restoreGState()
    brand.draw(at: CGPoint(x: brandX + iconSize + 28, y: 92 + (iconSize - brand.size().height) / 2))

    drawCentered(page.title, font: NSFont(name: "HiraginoSans-W8", size: 124)!, color: navy, y: 268, maxWidth: 1820)
    drawCentered(page.subtitle, font: NSFont(name: "HiraginoSans-W6", size: 54)!, color: secondary, y: 452, maxWidth: 1820)

    // 画面：白いフチと影をつけて角を丸める
    let screen = loadCG(raw.appendingPathComponent(page.source))
    let screenWidth = screenHeight * CGFloat(screen.width) / CGFloat(screen.height)
    let screenRect = CGRect(x: (CGFloat(width) - screenWidth) / 2, y: screenTop, width: screenWidth, height: screenHeight)
    let frameRect = screenRect.insetBy(dx: -20, dy: -20)
    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: 26), blur: 70, color: rgb(22, 36, 52, 0.28).cgColor)
    cg.addPath(roundedPath(frameRect, screenRadius + 20))
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

    NSGraphicsContext.current = nil
    try! FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
    let url = out.appendingPathComponent(page.output)
    try! NSBitmapImageRep(cgImage: cg.makeImage()!).representation(using: .png, properties: [:])!.write(to: url)
    return url
}

for page in pages {
    print(render(page).path)
}
