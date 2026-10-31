import SwiftUI
import SwiftData

/// 商店：卡片式商品列表；下拉刷新展示账户明细；内置背包入口
struct ShopView: View {
    @Environment(GameStore.self) private var store
    @Query private var heroes: [HeroProfile]
    @Query(filter: #Predicate<ShopItem> { $0.isActive },
           sort: [SortDescriptor(\ShopItem.sortOrder)])
    private var items: [ShopItem]
    @State private var showBackpack = false
    @State private var showLedger = false
    @State private var purchaseAlert: PurchaseAlert?

    struct PurchaseAlert: Identifiable {
        enum Kind: Equatable {
            case success(name: String)
            case insufficient
        }
        let id = UUID()
        let kind: Kind
    }

    private var hero: HeroProfile? { heroes.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if showLedger {
                        LedgerSection()
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    ForEach(items, id: \.id) { item in
                        ShopItemCard(item: item, coin: hero?.coin ?? 0) {
                            buy(item)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Selge.Palette.bg)
            .selgeScreenHeader {
                Button {
                    showBackpack = true
                } label: {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Selge.Palette.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Selge.Palette.surface))
                        .overlay(Circle().strokeBorder(Selge.Palette.border, lineWidth: 1))
                }
                .accessibilityLabel("背包")
            }
            .refreshable {
                // 下拉刷新：展示账户明细（金币/经验收支流水）
                guard !showLedger else { return }
                withAnimation(.easeInOut(duration: 0.25)) { showLedger = true }
            }
            .sheet(isPresented: $showBackpack) {
                BackpackView()
            }
            .alert(
                purchaseAlert?.kind == .insufficient ? "金币不足" : "购买成功",
                isPresented: .init(
                    get: { purchaseAlert != nil },
                    set: { if !$0 { purchaseAlert = nil } }
                )
            ) {
                Button("好", role: .cancel) {}
            } message: {
                switch purchaseAlert?.kind {
                case .success(let name):
                    Text("「\(name)」已放入背包")
                default:
                    Text("余额不够，先去历险赚点金币吧")
                }
            }
        }
    }

    private func buy(_ item: ShopItem) {
        switch store.purchase(item: item) {
        case .success(let purchased):
            purchaseAlert = .init(kind: .success(name: purchased.name))
        case .insufficientFunds:
            purchaseAlert = .init(kind: .insufficient)
        }
    }
}

// MARK: - 商品卡片

private struct ShopItemCard: View {
    let item: ShopItem
    let coin: Int
    let action: () -> Void

    private var affordable: Bool { coin >= item.priceCoin }

    var body: some View {
        HStack(spacing: 14) {
            Text(item.emoji)
                .font(.system(size: 30))
                .frame(width: 52, height: 52)
                .background(Selge.Palette.bg2)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Selge.Palette.textPrimary)
                Text(item.itemDescription)
                    .font(.system(size: 12))
                    .foregroundStyle(Selge.Palette.textTertiary)
                HStack(spacing: 3) {
                    Image(systemName: "circlebadge.2.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Selge.Palette.coinGoldDeep)
                    Text("\(item.priceCoin)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Selge.Palette.coinGoldDeep)
                }
            }
            Spacer()
            Button(action: action) {
                Text("购买")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(affordable ? AnyShapeStyle(Selge.accentGradient) : AnyShapeStyle(Selge.Palette.border))
                    .clipShape(Capsule())
            }
            .disabled(!affordable)
            .buttonStyle(.plain)
        }
        .padding(14)
        .selgeCard()
    }
}

// MARK: - 账户明细区块（下拉刷新后展示）

struct LedgerSection: View {
    @Environment(GameStore.self) private var store
    @State private var expanded = false

    private var transactions: [AccountTransaction] {
        store.recentTransactions(limit: expanded ? 30 : 8)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("账户明细")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Selge.Palette.textPrimary)
                Spacer()
                if !expanded && store.recentTransactions(limit: 30).count > 8 {
                    Button("展开") { withAnimation { expanded = true } }
                        .font(.system(size: 12))
                        .foregroundStyle(Selge.Palette.accent)
                }
            }
            if transactions.isEmpty {
                Text("暂无收支流水，去完成一次历险吧")
                    .font(.system(size: 12))
                    .foregroundStyle(Selge.Palette.textTertiary)
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 0) {
                    ForEach(transactions, id: \.id) { transaction in
                        LedgerRow(transaction: transaction)
                    }
                }
            }
        }
        .padding(14)
        .selgeCard()
    }
}

struct LedgerRow: View {
    let transaction: AccountTransaction

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.reason)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Selge.Palette.textPrimary)
                Text(Self.timeFormatter.string(from: transaction.at))
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Selge.Palette.textTertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if transaction.xpDelta != 0 {
                    Text("\(transaction.xpDelta > 0 ? "+" : "")\(transaction.xpDelta) xp")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Selge.Palette.accent)
                }
                if transaction.coinDelta != 0 {
                    Text("\(transaction.coinDelta > 0 ? "+" : "")\(transaction.coinDelta)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(transaction.coinDelta >= 0 ? Selge.Palette.coinGoldDeep : Selge.Palette.textSecondary)
                }
            }
        }
        .padding(.vertical, 7)
    }

    private var icon: String {
        transaction.coinDelta < 0 ? "cart" : (transaction.xpDelta > 0 ? "figure.hiking" : "shippingbox")
    }

    private var tint: Color {
        transaction.coinDelta < 0 ? Selge.Palette.coinGoldDeep : Selge.Palette.accent
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd HH:mm"
        return formatter
    }()
}
