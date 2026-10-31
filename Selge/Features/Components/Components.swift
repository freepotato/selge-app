import SwiftUI

/// 金币展示（金色圆形硬币符号 + 数值）
struct CoinText: View {
    let value: Int
    var font: Font = .system(size: 15, weight: .semibold, design: .rounded)

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "circlebadge.2.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Selge.Palette.coinGoldDeep)
            Text("\(value)")
                .font(font)
                .monospacedDigit()
                .foregroundStyle(Selge.Palette.textPrimary)
        }
    }
}

/// 经验进度条（当前等级内进度）
struct XPProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Selge.Palette.bg2)
                Capsule()
                    .fill(Selge.accentGradient)
                    .frame(width: max(8, proxy.size.width * fraction))
                    .animation(.easeInOut(duration: 0.4), value: fraction)
            }
        }
        .frame(height: 8)
    }
}

/// 主页类别统计卡片（免费版固定一行 3 张，付费版预留多行多卡片）
struct StatCardView: View {
    let emoji: String
    let name: String
    let count: Int

    var body: some View {
        VStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 26))
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Selge.Palette.textSecondary)
            Text("\(count)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Selge.Palette.textPrimary)
            Text("次")
                .font(.system(size: 10))
                .foregroundStyle(Selge.Palette.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .selgeCard()
    }
}
