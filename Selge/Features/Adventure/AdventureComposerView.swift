import SwiftUI
import SwiftData

/// 添加历险（主页右下角 + 按钮弹出的原生表单：标题 / 下拉类别 / 时长）
struct AdventureComposerView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\AdventureCategory.sortOrder), SortDescriptor(\AdventureCategory.createdAt)])
    private var categories: [AdventureCategory]

    @State private var title = ""
    @State private var selectedCategoryId: UUID?
    @State private var minutesText = ""
    @State private var result: SettlementResult?
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case title
        case minutes
    }

    private var selectedCategory: AdventureCategory? {
        if let selectedCategoryId, let match = categories.first(where: { $0.id == selectedCategoryId }) {
            return match
        }
        return categories.first
    }

    private var minutes: Double { Double(minutesText) ?? 0 }

    private var estimatedXP: Int {
        guard let category = selectedCategory else { return 0 }
        switch category.kind {
        case .time: return GameRules.xp(minutes: minutes, perMinute: category.xpPerMinute)
        case .once: return category.baseXP
        }
    }

    private var estimatedCoin: Int {
        GameRules.coin(forXP: estimatedXP, multiplier: store.config.coinMultiplier)
    }

    private var canSubmit: Bool {
        guard let category = selectedCategory else { return false }
        if category.kind == .time { return minutes > 0 }
        return true
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("标题（可选），如：傍晚的公园散步", text: $title)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.done)

                    Picker("类别", selection: $selectedCategoryId) {
                        ForEach(categories, id: \.id) { category in
                            Text("\(category.emoji)  \(category.name)")
                                .tag(Optional(category.id))
                        }
                    }
                    .pickerStyle(.menu)

                    if let category = selectedCategory, category.kind == .time {
                        HStack(spacing: 8) {
                            Text("时长")
                            Spacer(minLength: 8)
                            TextField("0", text: $minutesText, prompt: Text("0"))
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: .minutes)
                                .multilineTextAlignment(.trailing)
                                .monospacedDigit()
                                .frame(width: 56)
                            Text("分钟")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("记录一次历险")
                }
            }
            .listStyle(.insetGrouped)
            .tint(Selge.Palette.accent)
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(Selge.Palette.bg)
            .dismissKeyboardOnTapOutside()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                confirmBar
            }
            .navigationTitle("添加历险")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { focusedField = nil }
                }
            }
            .alert("历险完成", isPresented: Binding(
                get: { result != nil },
                set: { if !$0 { result = nil } }
            )) {
                Button("好") { dismiss() }
            } message: {
                if let result {
                    Text(alertText(result))
                }
            }
            .onAppear {
                if selectedCategoryId == nil { selectedCategoryId = categories.first?.id }
            }
        }
    }

    private func alertText(_ result: SettlementResult) -> String {
        var lines = [
            "「\(result.title)」",
            "+\(result.xp) xp · +\(result.coin) 金币",
        ]
        if result.afterLevel > result.beforeLevel {
            lines.append("升到 Lv.\(result.afterLevel)")
        }
        if !result.newAchievements.isEmpty {
            lines.append("解锁成就：" + result.newAchievements.map(\.name).joined(separator: "、"))
        }
        return lines.joined(separator: "\n")
    }

    // MARK: 确定按钮 + 预计收益（固定在键盘上方，始终可点）

    private var confirmBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text("预计")
                    .foregroundStyle(.secondary)
                Text("+\(estimatedXP) xp")
                    .fontWeight(.medium)
                    .foregroundStyle(Selge.Palette.accent)
                Text("·")
                    .foregroundStyle(.secondary)
                Text("+\(estimatedCoin) 金币")
                    .fontWeight(.medium)
                    .foregroundStyle(Selge.Palette.coinGoldDeep)
            }
            .font(.footnote)
            .monospacedDigit()

            Button {
                submit()
            } label: {
                Text("确定")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canSubmit)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Selge.Palette.bg)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func submit() {
        guard let category = selectedCategory else { return }
        let settlement = store.settle(category: category, minutes: minutes, title: title)
        result = settlement
        title = ""
        minutesText = ""
        focusedField = nil
    }
}
