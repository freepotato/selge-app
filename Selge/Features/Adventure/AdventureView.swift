import SwiftUI
import SwiftData

/// 历险页：输入标题 + 原生下拉选择类别 + 确定 → 直接结算写入记录；下方用原生列表展示全部历险记录。
/// 记录行使用系统原生左滑操作（修改 / 删除），保证点击可靠。
struct AdventureView: View {
    @Environment(GameStore.self) private var store
    @Query(sort: [SortDescriptor(\AdventureCategory.sortOrder), SortDescriptor(\AdventureCategory.createdAt)])
    private var categories: [AdventureCategory]
    @Query(sort: [SortDescriptor(\AdventureRecord.endedAt, order: .reverse)])
    private var records: [AdventureRecord]

    @State private var title = ""
    @State private var selectedCategoryId: UUID?
    @State private var minutesText = ""
    @State private var result: SettlementResult?
    @State private var editingRecord: AdventureRecord?
    @State private var pendingDelete: AdventureRecord?
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
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        if category.kind == .time { return minutes > 0 }
        return true
    }

    var body: some View {
        NavigationStack {
            List {
                entrySection
                confirmSection
                recordsSection
            }
            .listStyle(.insetGrouped)
            .tint(Selge.Palette.accent)
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(Selge.Palette.bg)
            // 点击任意其他区域收起键盘（不干扰行内按钮与下拉菜单）
            .simultaneousGesture(TapGesture().onEnded { focusedField = nil })
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { focusedField = nil }
                }
            }
            .selgeScreenHeader()
            .alert("历险完成", isPresented: Binding(
                get: { result != nil },
                set: { if !$0 { result = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                if let result {
                    Text(alertText(result))
                }
            }
            .alert("删除这条历险记录？", isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            )) {
                Button("删除", role: .destructive) {
                    if let record = pendingDelete { store.deleteRecord(record) }
                    pendingDelete = nil
                }
                Button("取消", role: .cancel) { pendingDelete = nil }
            } message: {
                if let record = pendingDelete {
                    Text("「\(titleText(for: record))」带来的 +\(record.xp) xp、+\(record.coin) 金币及对应的账户流水都会一并删除，且无法恢复。")
                }
            }
            .sheet(item: $editingRecord) { record in
                RecordEditorView(record: record)
            }
            .onAppear {
                if selectedCategoryId == nil { selectedCategoryId = categories.first?.id }
            }
        }
    }

    private func titleText(for record: AdventureRecord) -> String {
        let note = (record.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return note.isEmpty ? record.categoryName : note
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

    // MARK: - 记录一次历险（原生表单：标题 / 下拉类别 / 时长）

    private var entrySection: some View {
        Section {
            TextField("历险标题，如：傍晚的公园散步", text: $title)
                .focused($focusedField, equals: .title)
                .submitLabel(.done)

            Picker("类别", selection: $selectedCategoryId) {
                ForEach(categories, id: \.id) { category in
                    Text("\(category.emoji)  \(category.name)")
                        .tag(Optional(category.id))
                }
            }

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

    // MARK: - 确定按钮 + 预计收益

    private var confirmSection: some View {
        Section {
            Button {
                submit()
            } label: {
                Text("确定")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .disabled(!canSubmit)
        } footer: {
            HStack(spacing: 4) {
                Text("预计")
                Text("+\(estimatedXP) xp")
                    .fontWeight(.medium)
                    .foregroundStyle(Selge.Palette.accent)
                Text("·")
                Text("+\(estimatedCoin) 金币")
                    .fontWeight(.medium)
                    .foregroundStyle(Selge.Palette.coinGoldDeep)
            }
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

    // MARK: - 历险记录（原生列表 + 原生左滑操作）

    private var recordsSection: some View {
        Section {
            if records.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "figure.hiking")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(.secondary)
                    Text("还没有历险记录，写下第一件吧")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ForEach(records, id: \.id) { record in
                    RecordRow(record: record)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDelete = record
                            } label: {
                                Label("删除", systemImage: "trash")
                            }

                            Button {
                                editingRecord = record
                            } label: {
                                Label("修改", systemImage: "pencil")
                            }
                            .tint(Selge.Palette.accent)
                        }
                }
            }
        } header: {
            HStack {
                Text("历险记录")
                Spacer()
                if !records.isEmpty {
                    Text("\(records.count) 条")
                        .monospacedDigit()
                }
            }
        }
    }
}

// MARK: - 单条历险记录内容（原生列表行样式）

private struct RecordRow: View {
    let record: AdventureRecord

    private var titleText: String {
        let note = (record.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return note.isEmpty ? record.categoryName : note
    }

    private var metaText: String {
        var parts = [record.categoryName, Self.dateFormatter.string(from: record.endedAt)]
        if record.minutes > 0 {
            parts.append("\(Int(record.minutes.rounded())) 分钟")
        } else {
            parts.append("单次")
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(record.emoji)
                .font(.system(size: 20))
                .frame(width: 36, height: 36)
                .background(Selge.Palette.accentSoftBg)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(titleText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Selge.Palette.textPrimary)
                    .lineLimit(1)
                Text(metaText)
                    .font(.system(size: 12, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text("+\(record.xp) xp")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Selge.Palette.accent)
                Text("+\(record.coin)")
                    .font(.system(size: 11, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Selge.Palette.coinGoldDeep)
            }
        }
        .padding(.vertical, 2)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()
}

// MARK: - 修改历险

private struct RecordEditorView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let record: AdventureRecord

    @State private var title = ""
    @State private var endedAt = Date.now
    @State private var minutesText = ""
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case minutes
    }

    private var minutes: Double {
        record.kind == .time ? max(0, Double(minutesText) ?? 0) : 0
    }

    private var previewXP: Int {
        store.recalculatedXP(for: record, minutes: minutes)
    }

    private var previewCoin: Int {
        GameRules.coin(forXP: previewXP, multiplier: store.config.coinMultiplier)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("内容") {
                    TextField("标题", text: $title)
                    DatePicker("记录时间", selection: $endedAt)
                }

                if record.kind == .time {
                    Section("时长") {
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
                }

                Section {
                    LabeledContent("经验", value: "+\(previewXP) xp")
                        .monospacedDigit()
                    LabeledContent("金币", value: "+\(previewCoin)")
                        .monospacedDigit()
                } footer: {
                    Text("保存后按类别规则重新计算，并同步调整账户总经验、金币与流水")
                }
            }
            .tint(Selge.Palette.accent)
            .navigationTitle("修改历险")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { focusedField = nil }
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        title = (record.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        endedAt = record.endedAt
        if record.kind == .time {
            minutesText = "\(Int(record.minutes.rounded()))"
        }
    }

    private func save() {
        store.updateRecord(record, title: title, endedAt: endedAt, minutes: minutes)
        dismiss()
    }
}
