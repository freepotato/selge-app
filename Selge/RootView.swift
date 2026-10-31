import SwiftUI

/// 全局框架：底部 4 个一级页面（主页 / 历险 / 商店 / 成就），
/// 设置页仅通过各页面右上角齿轮入口进入。
struct RootView: View {
    enum Tab: Int, CaseIterable {
        case home, adventure, shop, achievements

        var title: String {
            switch self {
            case .home: return "主页"
            case .adventure: return "历险"
            case .shop: return "商店"
            case .achievements: return "成就"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .adventure: return "figure.hiking"
            case .shop: return "cart.fill"
            case .achievements: return "rosette"
            }
        }
    }

    @State private var selection: Tab = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label(Tab.home.title, systemImage: Tab.home.icon) }
                .tag(Tab.home)

            AdventureView()
                .tabItem { Label(Tab.adventure.title, systemImage: Tab.adventure.icon) }
                .tag(Tab.adventure)

            ShopView()
                .tabItem { Label(Tab.shop.title, systemImage: Tab.shop.icon) }
                .tag(Tab.shop)

            AchievementsView()
                .tabItem { Label(Tab.achievements.title, systemImage: Tab.achievements.icon) }
                .tag(Tab.achievements)
        }
        .tint(Selge.Palette.accent)
    }
}

/// 每个一级页面统一的顶部：左上角宋体 Selge Logo + 右上角设置齿轮。
/// 使用自定义顶栏而非系统 toolbar，避免 iOS 26 液态玻璃将文字 Logo 裁切成圆形。
struct ScreenHeaderModifier<Trailing: View>: ViewModifier {
    @State private var showSettings = false
    @ViewBuilder let trailing: () -> Trailing

    func body(content: Content) -> some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack(spacing: 12) {
                    Text("Selge")
                        .font(Selge.logoFont(22))
                        .foregroundStyle(Selge.Palette.accent)
                    Spacer()
                    trailing()
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(Selge.Palette.accent)
                    }
                    .accessibilityLabel("设置")
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 10)
                .background(Selge.Palette.bg)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
    }
}

extension View {
    func selgeScreenHeader(@ViewBuilder trailing: @escaping () -> some View = { EmptyView() }) -> some View {
        modifier(ScreenHeaderModifier(trailing: trailing))
    }
}
