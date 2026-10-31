import SwiftUI
import SwiftData

/// 商店：原生列表商品行；下拉刷新展示账户明细；内置背包入口
struct ShopView: View {
    @Environment(GameStore.self) private var store
    @Query private var heroes: [HeroProfile]
    @Query(filter: #Predicate<ShopItem> { $0.isActive },
           sort: [SortDescriptor(\ShopItem.sortOrder)])
    private var items: [ShopItem]
    @State private var showBackpack = false
    @State private var showLedger = false
    @State private var ledgerExpanded = false
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

    private var transactions: [AccountTransaction] {
        store.recentTransactions(limit: ledgerExpanded ? 30 : 8)
    }

    var body: some View {
        NavigationStack {
            List {
                balanceSection
                if showLedger {
                    ledgerSection
                }
                shopSection
            }
            .listStyle(.insetGrouped)
            .tint(Selge.Palette.accent)
            .scrollContentBackground(.hidden)
            .background(Selge.Palette.bg)
            .selgeScreenHeader {
                Button {
                    showBackpack = true
                } label: {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Selge.Palette.accent)
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

    // MARK: - 金币余额（置顶展示）

    private var balanceSection: some View {
        Section {
            LabeledContent("金币") {
                CoinText(value: hero?.coin ?? 0, font: .system(size: 17, weight: .semibold, design: .rounded))
            }
        }
    }

    // MARK: - 商品列表（原生行 + 原生按钮）

    private var shopSection: some View {
        Section {
            ForEach(items, id: \.id) { item in
                ShopItemRow(item: item, coin: hero?.coin ?? 0) {
                    buy(item)
                }
            }
        } header: {
            Text("商品")
        }
    }

    // MARK: - 账户明细（下拉刷新后展示）

    private var ledgerSection: some View {
        Section {
            if transactions.isEmpty {
                Text("暂无收支流水，去完成一次历险吧")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(transactions, id: \.id) { transaction in
                    LedgerRow(transaction: transaction)
                }
                if !ledgerExpanded && store.recentTransactions(limit: 30).count > 8 {
                    Button("展开全部") {
                        withAnimation { ledgerExpanded = true }
                    }
                    .font(.footnote)
                }
            }
        } header: {
            Text("账户明细")
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

// MARK: - 商品行

private struct ShopItemRow: View {
    let item: ShopItem
    let coin: Int
    let action: () -> Void

    private var affordable: Bool { coin >= item.priceCoin }

    var body: some View {
        HStack(spacing: 12) {
            Text(item.emoji)
                .font(.system(size: 26))
                .frame(width: 44, height: 44)
                .background(Selge.Palette.bg2)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Selge.Palette.textPrimary)
                Text(item.itemDescription)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                HStack(spacing: 3) {
                    Image(systemName: "circlebadge.2.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Selge.Palette.coinGold)
                    Text("\(item.priceCoin)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Selge.Palette.coinGoldDeep)
                }
            }

            Spacer(minLength: 8)

            Button("购买", action: action)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!affordable)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 收支流水行

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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Selge.Palette.textPrimary)
                Text(Self.timeFormatter.string(from: transaction.at))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                if transaction.xpDelta != 0 {
                    Text("\(transaction.xpDelta > 0 ? "+" : "")\(transaction.xpDelta) xp")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Selge.Palette.accent)
                }
                if transaction.coinDelta != 0 {
                    Text("\(transaction.coinDelta > 0 ? "+" : "")\(transaction.coinDelta)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(transaction.coinDelta >= 0 ? Selge.Palette.coinGoldDeep : Selge.Palette.textSecondary)
                }
            }
        }
        .padding(.vertical, 2)
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
