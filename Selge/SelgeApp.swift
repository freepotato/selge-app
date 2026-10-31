import SwiftUI
import SwiftData

@main
struct SelgeApp: App {
    let container: ModelContainer
    @State private var store: GameStore?
    @State private var showSplash = true
    @AppStorage("app.appearance") private var appearanceRaw: String = AppConfig.Appearance.system.rawValue

    private var appearanceScheme: ColorScheme? {
        AppConfig.Appearance(rawValue: appearanceRaw)?.colorScheme
    }

    init() {
        let container = Persistence.makeContainer()
        self.container = container
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let store {
                    RootView()
                        .environment(store)
                        .splashOverlay(isVisible: $showSplash)
                } else {
                    // 等待 store 构建完成
                    Color(Selge.Palette.bg)
                }
            }
            .modelContainer(container)
            .preferredColorScheme(appearanceScheme)
            .task {
                if store == nil {
                    store = GameStore(context: container.mainContext)
                }
            }
        }
    }
}

/// 启动页：白色 S 标识 + 主题绿微渐变背景，短暂展示后淡出
private struct SplashOverlay: ViewModifier {
    @Binding var isVisible: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
            if isVisible {
                Selge.splashGradient
                    .ignoresSafeArea()
                    .overlay(
                        Text("S")
                            .font(Selge.logoFont(108))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.12), radius: 18, y: 4)
                    )
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                            withAnimation(.easeOut(duration: 0.45)) {
                                isVisible = false
                            }
                        }
                    }
            }
        }
    }
}

extension View {
    func splashOverlay(isVisible: Binding<Bool>) -> some View {
        modifier(SplashOverlay(isVisible: isVisible))
    }
}
