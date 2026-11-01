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

/// 监听窗口级点击并回调点击位置，不拦截任何原有手势，
/// 用于「点击某区域之外时执行动作」这类需求（挂在 SwiftUI 列表上会破坏行内按钮）。
struct WindowTapObserver: UIViewRepresentable {
    let onTap: (CGPoint) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        context.coordinator.install(on: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onTap = onTap
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onTap: (CGPoint) -> Void
        private weak var recognizer: UITapGestureRecognizer?

        init(onTap: @escaping (CGPoint) -> Void) {
            self.onTap = onTap
        }

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

        @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
            onTap(gesture.location(in: gesture.view))
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
        background(
            WindowTapObserver { _ in
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
            .frame(width: 0, height: 0)
        )
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
