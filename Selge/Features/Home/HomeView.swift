import SwiftUI
import SwiftData

/// 主页：原生分组列表 —— 账户、类别统计、历险热力图、最近历险记录（每页 5 条），
/// 右下角 + 按钮用于添加历险。
struct HomeView: View {
    @Environment(GameStore.self) private var store
    @Query private var heroes: [HeroProfile]
    @Query(sort: [SortDescriptor(\AdventureRecord.endedAt, order: .reverse)])
    private var records: [AdventureRecord]
    @Query private var categories: [AdventureCategory]

    @State private var selectedDay: HeatmapView.DayCell?
    @State private var heatmapFrame: CGRect = .zero
    @State private var showingComposer = false
    @State private var editingRecord: AdventureRecord?
    @State private var pendingDelete: AdventureRecord?
    @State private var page = 0

    private let pageSize = 5

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                List {
                    accountSection
                    statsSection
                    heatmapSection(width: max(0, proxy.size.width - 68))
                    recordsSection
                }
                .listStyle(.insetGrouped)
                .tint(Selge.Palette.accent)
                .scrollContentBackground(.hidden)
                .background(Selge.Palette.bg)
                .contentMargins(.bottom, 76, for: .scrollContent)
                .onPreferenceChange(HeatmapFrameKey.self) { heatmapFrame = $0 }
                .overlay(alignment: .bottomTrailing) { addButton }
                .selgeScreenHeader()
                .sheet(item: $editingRecord) { record in
                    RecordEditorView(record: record)
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
            }
            .background(
                // 点击热力图以外的区域时收起日期悬浮框（UIKit 层识别，不影响列表内按钮）
                WindowTapObserver { point in
                    if !heatmapFrame.contains(point) { selectedDay = nil }
                }
                .frame(width: 0, height: 0)
            )
            .sheet(isPresented: $showingComposer, onDismiss: { page = 0 }) {
                AdventureComposerView()
            }
        }
    }

    private var hero: HeroProfile? { heroes.first }

    private var progress: (level: Int, current: Int, needed: Int, fraction: Double) {
        GameRules.progress(forXP: hero?.xp ?? 0)
    }

    private func titleText(for record: AdventureRecord) -> String {
        let note = (record.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return note.isEmpty ? record.categoryName : note
    }

    // MARK: - 账户：等级 / 经验进度 / 金币

    private var accountSection: some View {
        Section {
            LabeledContent("等级") {
                Text("Lv.\(progress.level)")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Selge.Palette.accent)
            }

            VStack(alignment: .leading, spacing: 6) {
                XPProgressBar(fraction: progress.fraction)
                Text(progress.level >= GameRules.maxLevel
                     ? "已至巅峰"
                     : "\(progress.current) / \(progress.needed) xp")
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)

            LabeledContent("金币") {
                CoinText(value: hero?.coin ?? 0, font: .system(size: 17, weight: .semibold, design: .rounded))
            }
        } header: {
            Text("账户")
        }
    }

    // MARK: - 类别统计

    private var statsSection: some View {
        let limit = max(1, AppConfig.shared.homeCardLimit)
        let shown = categories
            .sorted {
                $0.sortOrder == $1.sortOrder
                    ? $0.createdAt < $1.createdAt
                    : $0.sortOrder < $1.sortOrder
            }
            .prefix(limit)
        let counts = Dictionary(grouping: records, by: \.categoryId).mapValues(\.count)

        return Section {
            ForEach(shown, id: \.id) { category in
                HStack(spacing: 10) {
                    Text(category.emoji)
                        .font(.system(size: 18))
                        .frame(width: 26, alignment: .leading)
                    Text(category.name)
                        .font(.system(size: 16))
                    Spacer(minLength: 8)
                    Text("\(counts[category.id] ?? 0) 次")
                        .font(.system(size: 15, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("类别统计")
        }
    }

    // MARK: - 历险热力图（按内容自然高度展示）

    private func heatmapSection(width: CGFloat) -> some View {
        Section {
            VStack(spacing: 10) {
                HeatmapView(records: records, selected: $selectedDay)
                    .frame(height: HeatmapView.intrinsicHeight(containerWidth: width))
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: HeatmapFrameKey.self, value: geo.frame(in: .global))
                        }
                    )
                heatmapLegend
            }
        } header: {
            Text("历险热力图")
        }
    }

    private var heatmapLegend: some View {
        HStack(spacing: 4) {
            Text("近 \(HeatmapView.weekColumnCount) 周")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Spacer()
            Text("少")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(legendColor(index))
                    .frame(width: 9, height: 9)
            }
            Text("多")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }

    private func legendColor(_ index: Int) -> Color {
        switch index {
        case 1: return Selge.Palette.heat1
        case 2: return Selge.Palette.heat2
        case 3: return Selge.Palette.heat3
        case 4: return Selge.Palette.heat4
        default: return Selge.Palette.heat
        }
    }

    // MARK: - 最近历险记录（每页 5 条，可翻页）

    private var recordsSection: some View {
        Section {
            if records.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "figure.hiking")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(.secondary)
                    Text("还没有历险记录，点右下角 + 添加")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            } else {
                ForEach(pageRecords, id: \.id) { record in
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

                if pageCount > 1 {
                    pagerRow
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

    private var pageCount: Int {
        max(1, (records.count + pageSize - 1) / pageSize)
    }

    private var currentPage: Int {
        min(page, pageCount - 1)
    }

    private var pageRecords: [AdventureRecord] {
        let start = currentPage * pageSize
        guard start < records.count else { return [] }
        return Array(records[start..<min(start + pageSize, records.count)])
    }

    private var pagerRow: some View {
        HStack {
            Button {
                page = max(0, currentPage - 1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.borderless)
            .disabled(currentPage == 0)

            Spacer()

            Text("第 \(currentPage + 1) / \(pageCount) 页")
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                page = min(pageCount - 1, currentPage + 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.borderless)
            .disabled(currentPage >= pageCount - 1)
        }
        .font(.system(size: 15, weight: .medium))
    }

    // MARK: - 右下角添加按钮

    private var addButton: some View {
        Button {
            showingComposer = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Selge.accentGradient))
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 10)
        .accessibilityLabel("添加历险")
    }
}

private struct HeatmapFrameKey: PreferenceKey {
    static let defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
