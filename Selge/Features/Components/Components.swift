import SwiftUI

/// 金币展示（金黄色硬币符号 + 金黄色数值）
struct CoinText: View {
    let value: Int
    var font: Font = .system(size: 15, weight: .semibold, design: .rounded)

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "circlebadge.2.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Selge.Palette.coinGold)
            Text("\(value)")
                .font(font)
                .monospacedDigit()
                .foregroundStyle(Selge.Palette.coinGoldDeep)
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
