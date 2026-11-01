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

/// 点击输入框以外的区域收起键盘。
/// 用 UIKit 层的点击识别（cancelsTouchesInView = false）实现，
/// 避免在 SwiftUI 列表上挂手势导致行内按钮 / 下拉菜单点不动。
struct DismissKeyboardOnTapOutside: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        context.coordinator.install(on: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var recognizer: UITapGestureRecognizer?

        func install(on view: UIView) {
            DispatchQueue.main.async { [weak view] in
                guard let window = view?.window, self.recognizer == nil else { return }
                let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap))
                tap.cancelsTouchesInView = false
                tap.delegate = self
                window.addGestureRecognizer(tap)
                self.recognizer = tap
            }
        }

        @objc private func handleTap() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }

        /// 点在输入框上时不触发，避免刚聚焦就被收起
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var view = touch.view
            while let current = view {
                if current is UITextField || current is UITextView { return false }
                view = current.superview
            }
            return true
        }
    }
}

extension View {
    /// 点击非输入区域自动收起键盘
    func dismissKeyboardOnTapOutside() -> some View {
        background(DismissKeyboardOnTapOutside().frame(width: 0, height: 0))
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
