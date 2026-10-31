import SwiftUI
import SwiftData

/// 历险页：输入标题 + 下拉选择类别 + 确定 → 直接结算写入记录；下方展示全部历险记录
/// 记录卡片支持左滑显示「修改 / 删除」。
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
    @FocusState private var titleFocused: Bool

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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    entryCard
                    recordList
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Selge.Palette.bg)
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

    // MARK: - 记录入口卡片

    private var entryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("记录一次历险")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Selge.Palette.textPrimary)

            TextField("这次历险的标题，如：傍晚的公园散步", text: $title)
                .focused($titleFocused)
                .submitLabel(.done)
                .font(.system(size: 14))
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(Selge.Palette.bg2)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            categoryMenu

            if let category = selectedCategory, category.kind == .time {
                minutesField
            }

            estimateRow

            Button(action: submit) {
                Text("确定")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(canSubmit ? AnyShapeStyle(Selge.accentGradient) : AnyShapeStyle(Selge.Palette.borderStrong))
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            }
            .disabled(!canSubmit)
        }
        .padding(16)
        .selgeCard()
    }

    /// 类别下拉列表（类别数量可随设置增加，避免横向平铺挤压）
    private var categoryMenu: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("类别")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Selge.Palette.textTertiary)

            Menu {
                ForEach(categories, id: \.id) { category in
                    Button {
                        selectedCategoryId = category.id
                    } label: {
                        Text("\(category.emoji)  \(category.name)")
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(selectedCategory?.emoji ?? "✨")
                        .font(.system(size: 16))
                    Text(selectedCategory?.name ?? "选择类别")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Selge.Palette.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Selge.Palette.textTertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(Selge.Palette.bg2)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private var minutesField: some View {
        HStack(spacing: 10) {
            Text("时长")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Selge.Palette.textTertiary)

            TextField("", text: $minutesText, prompt: Text("0"))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .frame(width: 56)

            Text("分钟")
                .font(.system(size: 13))
                .foregroundStyle(Selge.Palette.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Selge.Palette.bg2)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var estimateRow: some View {
        HStack(spacing: 6) {
            Text("预计")
                .font(.system(size: 11))
                .foregroundStyle(Selge.Palette.textTertiary)
            Text("+\(estimatedXP) xp")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Selge.Palette.accent)
            Text("·")
                .foregroundStyle(Selge.Palette.textTertiary)
            Text("+\(estimatedCoin) 金币")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Selge.Palette.coinGoldDeep)
            Spacer()
        }
    }

    private func submit() {
        guard let category = selectedCategory else { return }
        let settlement = store.settle(category: category, minutes: minutes, title: title)
        result = settlement
        title = ""
        minutesText = ""
        titleFocused = false
    }

    // MARK: - 历险记录

    private var recordList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("历险记录")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Selge.Palette.textSecondary)
                Spacer()
                if !records.isEmpty {
                    Text("\(records.count) 条")
                        .font(.system(size: 11, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Selge.Palette.textTertiary)
                }
            }

            if records.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "figure.hiking")
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(Selge.Palette.textTertiary)
                    Text("还没有历险记录，写下第一件吧")
                        .font(.system(size: 12))
                        .foregroundStyle(Selge.Palette.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
                .selgeCard()
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(records, id: \.id) { record in
                        SwipeableRecordRow(
                            record: record,
                            onEdit: { editingRecord = record },
                            onDelete: { pendingDelete = record }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - 可左滑操作的单条记录

private struct SwipeableRecordRow: View {
    let record: AdventureRecord
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var revealActions = false

    private let actionWidth: CGFloat = 64
    private let spacing: CGFloat = 8
    private var revealedWidth: CGFloat { actionWidth * 2 + spacing }

    var body: some View {
        ZStack(alignment: .trailing) {
            actionsBackground
            RecordRow(record: record)
                .offset(x: offset)
                .contentShape(Rectangle())
                .onTapGesture {
                    if revealActions { close() }
                }
                .simultaneousGesture(dragGesture)
        }
    }

    private var actionsBackground: some View {
        HStack(spacing: spacing) {
            actionButton(title: "修改", icon: "pencil", color: Selge.Palette.accent, action: onEdit)
            actionButton(title: "删除", icon: "trash", color: Color(hex: 0xc25a4a), action: onDelete)
        }
        .frame(height: 64)
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(.white)
            .frame(width: actionWidth, height: 64)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                // 只响应横向滑动，保证竖向滚动列表不受影响
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                let base = revealActions ? -revealedWidth : 0
                let proposed = base + value.translation.width
                offset = min(0, max(-revealedWidth - 14, proposed))
            }
            .onEnded { value in
                let base = revealActions ? -revealedWidth : 0
                let final = base + value.translation.width
                if final < -revealedWidth * 0.45 {
                    open()
                } else {
                    close()
                }
            }
    }

    private func open() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            offset = -revealedWidth
            revealActions = true
        }
    }

    private func close() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            offset = 0
            revealActions = false
        }
    }
}

// MARK: - 单条历险记录内容

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
        HStack(alignment: .center, spacing: 12) {
            Text(record.emoji)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(Selge.Palette.accentSoftBg)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(titleText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Selge.Palette.textPrimary)
                    .lineLimit(1)
                Text(metaText)
                    .font(.system(size: 11, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Selge.Palette.textTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text("+\(record.xp) xp")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Selge.Palette.accent)
                Text("+\(record.coin) 金币")
                    .font(.system(size: 11, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Selge.Palette.coinGoldDeep)
            }
        }
        .padding(12)
        .selgeCard()
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
                        HStack {
                            Text("分钟")
                            Spacer()
                            TextField("0", text: $minutesText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .monospacedDigit()
                                .frame(width: 80)
                        }
                    }
                }

                Section {
                    HStack {
                        Text("经验")
                        Spacer()
                        Text("+\(previewXP) xp")
                            .monospacedDigit()
                            .foregroundStyle(Selge.Palette.accent)
                    }
                    HStack {
                        Text("金币")
                        Spacer()
                        Text("+\(previewCoin)")
                            .monospacedDigit()
                            .foregroundStyle(Selge.Palette.coinGoldDeep)
                    }
                } footer: {
                    Text("保存后按类别规则重新计算，并同步调整账户总经验、金币与流水")
                }
            }
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
