import SwiftUI
import UIKit

// MARK: - 动态颜色（深浅色自动切换）

extension Color {
    /// 用十六进制创建颜色
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    /// 深浅色双值颜色（基于网站 CSS 变量体系）
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light))
        })
    }
}

// MARK: - Selge 设计令牌
// 提取自 Selge 网站 main.css 的橄榄绿色板，与 Web 端保持一致

enum Selge {
    // 基础橄榄绿梯度（g1 浅 → g6 深）
    static let g1 = Color(hex: 0xf0f4ee)
    static let g2 = Color(hex: 0xd4e4cc)
    static let g3 = Color(hex: 0x9aba8a)
    static let g4 = Color(hex: 0x5c8a4a)
    static let g5 = Color(hex: 0x3d6b30)
    static let g6 = Color(hex: 0x2a4d20)

    enum Palette {
        // 背景与表面
        static let bg = Color(light: 0xf7f6f3, dark: 0x1a1916)
        static let bg2 = Color(light: 0xefede8, dark: 0x222019)
        static let surface = Color(light: 0xffffff, dark: 0x252320)
        static let surface2 = Color(light: 0xf7f6f3, dark: 0x2c2a23)

        // 描边
        static let border = Color(light: 0xdedad3, dark: 0x3a3830)
        static let borderStrong = Color(light: 0xccc8bf, dark: 0x4a4840)

        // 文字
        static let textPrimary = Color(light: 0x1a1916, dark: 0xf0ede6)
        static let textSecondary = Color(light: 0x4a4840, dark: 0xc8c4bc)
        static let textTertiary = Color(light: 0x8a8780, dark: 0x7a7870)

        // 主色（强调）
        static let accent = Color(light: 0x3d6b30, dark: 0x9aba8a)
        static let accentSoftBg = Color(light: 0xf0f4ee, dark: 0x2a4020)
        static let accentBorder = Color(light: 0x9aba8a, dark: 0x3d6b30)

        // 金币
        static let coinGold = Color(hex: 0xf0c040)
        static let coinGoldDeep = Color(hex: 0xd4a017)

        // 热力图五档
        static let heat = Color(light: 0xeae8e3, dark: 0x2c2a23)
        static let heat1 = Color(light: 0xc8dbbf, dark: 0x2a4020)
        static let heat2 = Color(light: 0x9aba8a, dark: 0x3d6b30)
        static let heat3 = Color(light: 0x5c8a4a, dark: 0x5c8a4a)
        static let heat4 = Color(light: 0x3d6b30, dark: 0x9aba8a)
    }

    // MARK: 字体
    // Logo 使用宋体传递严谨清晰的调性，正文使用系统默认字体

    static func logoFont(_ size: CGFloat) -> Font {
        .custom("STSongti-SC-Bold", size: size)
    }

    static func logoFontRegular(_ size: CGFloat) -> Font {
        .custom("STSongti-SC-Regular", size: size)
    }

    // 主色微渐变（启动页 / 强调场景）：主题绿渐变，保证白色 S 标识清晰可见
    static var splashGradient: LinearGradient {
        LinearGradient(
            colors: [g4, g5, g6],
            startPoint: .top, endPoint: .bottom
        )
    }

    static var accentGradient: LinearGradient {
        LinearGradient(colors: [g4, g5], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - 卡片样式

struct SelgeCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Selge.Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Selge.Palette.border, lineWidth: 1)
            )
    }
}

extension View {
    func selgeCard() -> some View { modifier(SelgeCard()) }
}
