import SwiftUI
import SwiftData

/// 设置页：历险类型管理、深浅色模式、全局参数、版本与更新日志
struct SettingsView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [AdventureCategory]
    @State private var editingCategory: AdventureCategory?
    @State private var showAddForm = false
    @State private var showChangelog = false
    @AppStorage("app.appearance") private var appearanceRaw: String = AppConfig.Appearance.system.rawValue

    private var config: AppConfig { AppConfig.shared }

    private var appearance: AppConfig.Appearance {
        get { AppConfig.Appearance(rawValue: appearanceRaw) ?? .system }
        nonmutating set { appearanceRaw = newValue.rawValue }
    }

    private var sorted: [AdventureCategory] {
        categories.sorted {
            $0.sortOrder == $1.sortOrder
                ? $0.createdAt < $1.createdAt
                : $0.sortOrder < $1.sortOrder
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("历险类型") {
                    ForEach(sorted, id: \.id) { category in
                        Button {
                            editingCategory = category
                        } label: {
                            HStack(spacing: 10) {
                                Text(category.emoji).font(.system(size: 18))
                                Text(category.name)
                                    .foregroundStyle(Selge.Palette.textPrimary)
                                Spacer()
                                Text(category.ruleDescription)
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(Selge.Palette.textTertiary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            guard index < sorted.count else { continue }
                            store.deleteCategory(sorted[index])
                        }
                    }
                    Button {
                        showAddForm = true
                    } label: {
                        Label("添加历险类型", systemImage: "plus")
                            .foregroundStyle(Selge.Palette.accent)
                    }
                }

                Section("外观") {
                    Picker("深浅色模式", selection: Binding(
                        get: { appearance },
                        set: { appearance = $0 }
                    )) {
                        ForEach(AppConfig.Appearance.allCases) { appearance in
                            Text(appearance.label).tag(appearance)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    lockedParamRow(name: "金币倍率", value: String(format: "%.1f×", config.coinMultiplier))
                    lockedParamRow(name: "主页卡片数量", value: "\(config.homeCardLimit)")
                    lockedParamRow(name: "自定义成就", value: config.customAchievementsEnabled ? "开" : "关")
                } header: {
                    Text("参数配置")
                } footer: {
                    Text("以上参数当前版本锁定，付费版开放调整")
                }

                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(VersionInfo.display)
                            .font(.system(size: 14, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Selge.Palette.textSecondary)
                    }
                    Button {
                        showChangelog = true
                    } label: {
                        HStack {
                            Text("更新日志")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Selge.Palette.textTertiary)
                        }
                    }
                    HStack {
                        Text("iCloud 同步")
                        Spacer()
                        Text(Persistence.cloudKitEnabled ? "已启用" : "本地存储")
                            .font(.system(size: 14))
                            .foregroundStyle(Persistence.cloudKitEnabled ? Selge.Palette.accent : Selge.Palette.textTertiary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(Selge.Palette.accent)
                }
            }
            .sheet(item: $editingCategory) { category in
                CategoryFormView(category: category)
            }
            .sheet(isPresented: $showAddForm) {
                CategoryFormView(category: nil)
            }
            .sheet(isPresented: $showChangelog) {
                ChangelogView()
            }
        }
    }

    private func lockedParamRow(name: String, value: String) -> some View {
        HStack {
            Text(name)
            Spacer()
            Text(value)
                .font(.system(size: 14, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Selge.Palette.textSecondary)
            Image(systemName: "lock.fill")
                .font(.system(size: 10))
                .foregroundStyle(Selge.Palette.textTertiary)
        }
        // 免费版锁定；付费开关接口见 AppConfig
    }
}

extension AdventureCategory: Identifiable {}

/// 历险类型新增/编辑表单
struct CategoryFormView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let category: AdventureCategory?

    @State private var emoji: String = "✨"
    @State private var name: String = ""
    @State private var kind: AdventureKind = .time
    @State private var xpPerMinuteText: String = "1"
    @State private var baseXPText: String = "500"

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    HStack {
                        Text("图标")
                        TextField("✨", text: $emoji)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(Selge.Palette.textSecondary)
                    }
                    TextField("名称（如：跑步）", text: $name)
                    Picker("结算方式", selection: $kind) {
                        ForEach(AdventureKind.allCases, id: \.self) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                switch kind {
                case .time:
                    Section("经验规则") {
                        HStack {
                            Text("每分钟经验")
                            TextField("1", text: $xpPerMinuteText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                case .once:
                    Section("经验规则") {
                        HStack {
                            Text("单次经验")
                            TextField("500", text: $baseXPText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
            .navigationTitle(category == nil ? "添加历险类型" : "编辑历险类型")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let category else { return }
        emoji = category.emoji
        name = category.name
        kind = category.kind
        if category.kind == .time {
            xpPerMinuteText = String(format: "%.2f", category.xpPerMinute)
        } else {
            baseXPText = "\(category.baseXP)"
        }
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespaces)
        guard !cleanName.isEmpty else { return }

        if let category {
            category.emoji = emoji.isEmpty ? "✨" : emoji
            category.name = cleanName
            category.kind = kind
            if kind == .time {
                category.xpPerMinute = Double(xpPerMinuteText) ?? 0
                category.baseXP = 0
            } else {
                category.baseXP = Int(baseXPText) ?? 0
                category.xpPerMinute = 0
            }
        } else {
            store.addCategory(
                emoji: emoji,
                name: cleanName,
                kind: kind,
                xpPerMinute: kind == .time ? (Double(xpPerMinuteText) ?? 0) : 0,
                baseXP: kind == .once ? (Int(baseXPText) ?? 0) : 0
            )
        }
        dismiss()
    }
}
