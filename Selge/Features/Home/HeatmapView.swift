import SwiftUI

/// 历险热力图（GitHub 贡献图样式，无标题文字）
/// 列 = 周，行 = 周日～周六；颜色深浅代表当日历险次数
struct HeatmapView: View {
    let records: [AdventureRecord]

    private static let calendar = Calendar.current
    private static let weekColumns = 22

    var body: some View {
        GeometryReader { proxy in
            let grid = Self.buildGrid(records: records)
            let gap: CGFloat = 2
            let weeks = grid.count
            let cellW = weeks > 1 ? (proxy.size.width - gap * CGFloat(weeks - 1)) / CGFloat(weeks) : proxy.size.width
            let cellH = (proxy.size.height - gap * 6) / 7
            let cell = max(4, min(cellW, cellH))

            HStack(alignment: .top, spacing: gap) {
                ForEach(grid.indices, id: \.self) { weekIndex in
                    let week = grid[weekIndex]
                    VStack(spacing: gap) {
                        ForEach(week.indices, id: \.self) { dayIndex in
                            let day = week[dayIndex]
                            RoundedRectangle(cornerRadius: cell * 0.22, style: .continuous)
                                .fill(day.fill)
                                .aspectRatio(1, contentMode: .fit)
                                .frame(maxWidth: cell)
                                .accessibilityLabel(day.accessibilityLabel)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    // MARK: - 数据构建

    struct DayCell: Hashable {
        let key: String
        let count: Int
        let isFuture: Bool
        let label: String

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

    static func buildGrid(records: [AdventureRecord], weeks: Int = Self.weekColumns) -> [[DayCell]] {
        let today = calendar.startOfDay(for: Date.now)
        let counts = Dictionary(grouping: records, by: \.dayKey).mapValues(\.count)

        // 对齐到本周周日（GitHub 风格：周日开始）
        let weekday = calendar.component(.weekday, from: today) // 1 = 周日
        let currentWeekStart = calendar.date(byAdding: .day, value: -(weekday - 1), to: today)!
        let firstWeekStart = calendar.date(byAdding: .day, value: -7 * (weeks - 1), to: currentWeekStart)!

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "M月d日"

        var grid: [[DayCell]] = []
        for week in 0..<weeks {
            var column: [DayCell] = []
            for dayIndex in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: week * 7 + dayIndex, to: firstWeekStart) else { continue }
                let isFuture = date > today
                let key = formatter.string(from: date)
                let count = counts[key] ?? 0
                column.append(DayCell(
                    key: key,
                    count: count,
                    isFuture: isFuture,
                    label: displayFormatter.string(from: date)
                ))
            }
            grid.append(column)
        }
        return grid
    }
}
