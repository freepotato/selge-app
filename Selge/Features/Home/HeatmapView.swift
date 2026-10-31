import SwiftUI

/// 历险热力图（GitHub 贡献图样式）
/// 列 = 周，行 = 周日～周六；顶部标注月份、左侧标注星期，
/// 按住任意方块（可拖动）显示该天的历险次数。
struct HeatmapView: View {
    let records: [AdventureRecord]
    /// 当前选中的日期（悬浮框会一直停留，直到点击其他区域清空）
    @Binding var selected: DayCell?

    private static let calendar = Calendar.current
    static let weekColumnCount = 22
    private static let gap: CGFloat = 3
    private static let weekdayLabelWidth: CGFloat = 20
    private static let monthLabelHeight: CGFloat = 15

    /// 按可用宽度计算热力图自然高度（正方形方块 + 月份/星期标注）
    static func intrinsicHeight(containerWidth: CGFloat) -> CGFloat {
        let availableWidth = max(0, containerWidth - weekdayLabelWidth)
        let cell = max(4, (availableWidth - gap * CGFloat(weekColumnCount - 1)) / CGFloat(weekColumnCount))
        return monthLabelHeight + cell * 7 + gap * 6
    }

    var body: some View {
        GeometryReader { proxy in
            let grid = Self.buildGrid(records: records)
            let metrics = Metrics(size: proxy.size, weeks: grid.count)

            ZStack(alignment: .topLeading) {
                monthLabels(grid: grid, metrics: metrics)
                weekdayLabels(metrics: metrics)
                cells(grid: grid, metrics: metrics)

                if let selected, let point = tooltipOffset(for: selected, grid: grid, metrics: metrics, size: proxy.size) {
                    tooltip(for: selected)
                        .offset(x: point.x, y: point.y)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .contentShape(Rectangle())
            // 高优先级手势：保证按住/滑动方块时不会被外层列表的点击手势清空悬浮框
            .highPriorityGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        // 手指滑出网格时保留上一个日期，避免提示频繁闪烁
                        if let hit = cell(at: value.location, grid: grid, metrics: metrics), hit != selected {
                            selected = hit
                        }
                    }
            )
            .animation(.easeOut(duration: 0.12), value: selected)
        }
    }

    // MARK: - 网格

    private func cells(grid: [[DayCell]], metrics: Metrics) -> some View {
        ForEach(grid.indices, id: \.self) { col in
            ForEach(grid[col].indices, id: \.self) { row in
                let day = grid[col][row]
                RoundedRectangle(cornerRadius: metrics.cell * 0.22, style: .continuous)
                    .fill(day.fill)
                    .frame(width: metrics.cell, height: metrics.cell)
                    .overlay {
                        if selected?.key == day.key {
                            RoundedRectangle(cornerRadius: metrics.cell * 0.22, style: .continuous)
                                .strokeBorder(Selge.Palette.textPrimary.opacity(0.8), lineWidth: 1.5)
                        }
                    }
                    .offset(x: metrics.x(col), y: metrics.y(row))
                    .accessibilityLabel(day.accessibilityLabel)
            }
        }
    }

    /// 月份标签：某列起始日进入新月份时，在该列上方显示「x月」
    private func monthLabels(grid: [[DayCell]], metrics: Metrics) -> some View {
        let labels = monthLabelItems(grid: grid)
        return ForEach(labels, id: \.column) { item in
            Text(item.text)
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(Selge.Palette.textTertiary)
                .fixedSize()
                .offset(x: metrics.x(item.column), y: metrics.originY - Self.monthLabelHeight + 2)
        }
    }

    /// 星期标签：与 GitHub 一致，只标注周一、周三、周五（行 1 / 3 / 5）
    private func weekdayLabels(metrics: Metrics) -> some View {
        ForEach([1, 3, 5], id: \.self) { row in
            Text(Self.weekdayText(row))
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(Selge.Palette.textTertiary)
                .frame(width: Self.weekdayLabelWidth - 4, height: metrics.cell, alignment: .trailing)
                .offset(x: 0, y: metrics.y(row))
        }
    }

    /// 悬浮提示：展示当日日期与历险次数
    private func tooltip(for day: DayCell) -> some View {
        Text("\(day.label) · \(day.count) 次历险")
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(Selge.Palette.surface)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Selge.Palette.textPrimary.opacity(0.9))
            .clipShape(Capsule())
            .fixedSize()
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            .allowsHitTesting(false)
    }

    // MARK: - 命中与定位

    private func cell(at location: CGPoint, grid: [[DayCell]], metrics: Metrics) -> DayCell? {
        let step = metrics.cell + Self.gap
        guard location.x >= metrics.originX, location.y >= metrics.originY else { return nil }
        // 向下取整到最近的格子，手指落在间隙时也能命中相邻方块，避免提示闪烁
        let col = Int((location.x - metrics.originX) / step)
        let row = Int((location.y - metrics.originY) / step)
        guard col >= 0, col < grid.count, row >= 0, row < 7 else { return nil }
        let day = grid[col][row]
        return day.isFuture ? nil : day
    }

    private func tooltipOffset(for day: DayCell, grid: [[DayCell]], metrics: Metrics, size: CGSize) -> CGPoint? {
        guard let col = grid.firstIndex(where: { $0.contains(day) }),
              let row = grid[col].firstIndex(of: day) else {
            return nil
        }
        let centerX = metrics.x(col) + metrics.cell / 2
        let estimatedWidth: CGFloat = 108
        let x = min(max(centerX - estimatedWidth / 2, 0), max(0, size.width - estimatedWidth))
        let above = metrics.y(row) - 24
        let y = above > Self.monthLabelHeight ? above : metrics.y(row) + metrics.cell + 4
        return CGPoint(x: x, y: y)
    }

    private func monthLabelItems(grid: [[DayCell]]) -> [(column: Int, text: String)] {
        var items: [(Int, String)] = []
        var lastMonth = -1
        var lastColumn = -100
        for (col, week) in grid.enumerated() {
            guard let first = week.first else { continue }
            let month = Self.calendar.component(.month, from: first.date)
            if month != lastMonth, col - lastColumn >= 3 {
                items.append((col, "\(month)月"))
                lastMonth = month
                lastColumn = col
            }
        }
        return items
    }

    private static func weekdayText(_ row: Int) -> String {
        switch row {
        case 1: return "一"
        case 3: return "三"
        case 5: return "五"
        default: return ""
        }
    }

    // MARK: - 度量

    private struct Metrics {
        let cell: CGFloat
        let originX: CGFloat
        let originY: CGFloat

        init(size: CGSize, weeks: Int) {
            let availableWidth = max(0, size.width - HeatmapView.weekdayLabelWidth)
            let availableHeight = max(0, size.height - HeatmapView.monthLabelHeight)
            let byWidth = (availableWidth - HeatmapView.gap * CGFloat(weeks - 1)) / CGFloat(max(weeks, 1))
            let byHeight = (availableHeight - HeatmapView.gap * 6) / 7
            let cell = max(4, min(byWidth, byHeight))
            let gridWidth = cell * CGFloat(weeks) + HeatmapView.gap * CGFloat(weeks - 1)
            let gridHeight = cell * 7 + HeatmapView.gap * 6
            self.cell = cell
            self.originX = HeatmapView.weekdayLabelWidth + max(0, (availableWidth - gridWidth) / 2)
            // 垂直居中，避免主页下方出现大片空白
            self.originY = HeatmapView.monthLabelHeight + max(0, (availableHeight - gridHeight) / 2)
        }

        func x(_ col: Int) -> CGFloat { originX + CGFloat(col) * (cell + HeatmapView.gap) }
        func y(_ row: Int) -> CGFloat { originY + CGFloat(row) * (cell + HeatmapView.gap) }
    }

    // MARK: - 数据构建

    struct DayCell: Hashable {
        let key: String
        let count: Int
        let isFuture: Bool
        let label: String
        let date: Date

        var fill: Color {
            if isFuture { return .clear }
            switch GameRules.heatLevel(forCount: count) {
            case 1: return Selge.Palette.heat1
            case 2: return Selge.Palette.heat2
            case 3: return Selge.Palette.heat3
            case 4: return Selge.Palette.heat4
            default: return Selge.Palette.heat
            }
        }

        var accessibilityLabel: String {
            isFuture ? "" : "\(label)，\(count) 次历险"
        }
    }

    static func buildGrid(records: [AdventureRecord], weeks: Int = Self.weekColumnCount) -> [[DayCell]] {
        let today = calendar.startOfDay(for: Date.now)
        let counts = Dictionary(grouping: records, by: \.dayKey).mapValues(\.count)

        // 对齐到本周周日（GitHub 风格：周日开始）
        let weekday = calendar.component(.weekday, from: today) // 1 = 周日
        let currentWeekStart = calendar.date(byAdding: .day, value: -(weekday - 1), to: today)!
        let firstWeekStart = calendar.date(byAdding: .day, value: -7 * (weeks - 1), to: currentWeekStart)!

        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyy-MM-dd"
        keyFormatter.locale = Locale(identifier: "en_US_POSIX")

        var grid: [[DayCell]] = []
        for week in 0..<weeks {
            var column: [DayCell] = []
            for dayIndex in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: week * 7 + dayIndex, to: firstWeekStart) else { continue }
                let isFuture = date > today
                let key = keyFormatter.string(from: date)
                column.append(DayCell(
                    key: key,
                    count: counts[key] ?? 0,
                    isFuture: isFuture,
                    label: labelText(for: date),
                    date: date
                ))
            }
            grid.append(column)
        }
        return grid
    }

    private static func labelText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}
