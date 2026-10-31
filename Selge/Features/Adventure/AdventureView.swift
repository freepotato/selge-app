import SwiftUI
import SwiftData

/// 历险页：输入标题 + 选择类别 + 确定 → 直接结算写入记录；下方展示全部历险记录
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

            categoryPicker

            if let category = selectedCategory, category.kind == .time {
                minutesField(category)
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

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("类别")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Selge.Palette.textTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.id) { category in
                        let isSelected = category.id == selectedCategory?.id
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                selectedCategoryId = category.id
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Text(category.emoji)
                                    .font(.system(size: 14))
                                Text(category.name)
                                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                            }
                            .foregroundStyle(isSelected ? Selge.Palette.accent : Selge.Palette.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isSelected ? Selge.Palette.accentSoftBg : Selge.Palette.bg2)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().strokeBorder(
                                    isSelected ? Selge.Palette.accentBorder : .clear,
                                    lineWidth: 1
                                )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 1)
            }
        }
    }

    private func minutesField(_ category: AdventureCategory) -> some View {
        HStack(spacing: 10) {
            Text("时长")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Selge.Palette.textTertiary)

            TextField("", text: $minutesText, prompt: Text("0"))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .frame(width: 64)

            Text("分钟")
                .font(.system(size: 13))
                .foregroundStyle(Selge.Palette.textSecondary)

            Spacer()

            Text(String(format: "%.2f xp / 分钟", category.xpPerMinute))
                .font(.system(size: 11, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Selge.Palette.textTertiary)
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
                        RecordRow(record: record)
                    }
                }
            }
        }
    }
}

// MARK: - 单条历险记录

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
