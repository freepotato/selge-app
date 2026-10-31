import SwiftUI

/// 单类别历险会话：
/// - 计时型：开始计时 → 实时展示时长与预计经验/金币 → 结束结算
/// - 难度型（单次）：直接结算
/// 结算完成后写入记录、经验/金币、流水、成就与热力图。
struct AdventureSessionView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let category: AdventureCategory

    enum Phase {
        case ready
        case running
        case summary(SettlementResult)
    }

    @State private var phase: Phase = .ready
    @State private var startedAt: Date?

    private var isSummary: Bool {
        if case .summary = phase { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .ready:
                    readyView
                case .running:
                    runningView
                case .summary(let result):
                    summaryView(result)
                }
            }
            .padding(20)
            .background(Selge.Palette.bg)
            .navigationTitle("\(category.emoji) \(category.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !isSummary {
                        Button("取消") { dismiss() }
                            .foregroundStyle(Selge.Palette.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: 就绪

    private var readyView: some View {
        VStack(spacing: 24) {
            Spacer()
            Text(category.emoji)
                .font(.system(size: 72))
            Text(category.ruleDescription)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Selge.Palette.textSecondary)
            Spacer()
            mainButton(
                title: category.kind == .time ? "开始计时" : "完成一次历险",
                icon: category.kind == .time ? "play.fill" : "checkmark"
            ) {
                switch category.kind {
                case .time:
                    startedAt = Date.now
                    phase = .running
                case .once:
                    finish()
                }
            }
        }
    }

    // MARK: 计时中

    private var runningView: some View {
        VStack(spacing: 24) {
            Spacer()
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let elapsed = context.date.timeIntervalSince(startedAt ?? context.date)
                let minutes = max(0, elapsed / 60)
                VStack(spacing: 14) {
                    Text(timeString(elapsed))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Selge.Palette.textPrimary)
                        .contentTransition(.numericText())

                    HStack(spacing: 24) {
                        liveStat(label: "预计经验", value: "\(GameRules.xp(minutes: minutes, perMinute: category.xpPerMinute)) xp")
                        liveStat(label: "预计金币", value: "\(GameRules.coin(forXP: GameRules.xp(minutes: minutes, perMinute: category.xpPerMinute), multiplier: store.config.coinMultiplier))")
                    }
                }
            }
            Spacer()
            mainButton(title: "结束并结算", icon: "flag.checkered") { finish() }
        }
    }

    private func liveStat(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Selge.Palette.accent)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Selge.Palette.textTertiary)
        }
    }

    // MARK: 结算摘要

    private func summaryView(_ result: SettlementResult) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Text(result.emoji)
                .font(.system(size: 60))
            Text("历险完成")
                .font(Selge.logoFontRegular(22))
                .foregroundStyle(Selge.Palette.textPrimary)

            VStack(spacing: 12) {
                summaryRow(label: "历险", value: result.categoryName)
                if result.minutes > 0 {
                    summaryRow(label: "时长", value: timeString(result.minutes * 60))
                }
                summaryRow(label: "经验", value: "+\(result.xp) xp", highlight: true)
                summaryRow(label: "金币", value: "+\(result.coin)", highlight: true)
                summaryRow(label: "连续打卡", value: "\(result.streak) 天")
                if result.afterLevel > result.beforeLevel {
                    summaryRow(label: "升级", value: "Lv.\(result.afterLevel) \(GameRules.levelTitle(result.afterLevel))", highlight: true)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .selgeCard()

            if !result.newAchievements.isEmpty {
                VStack(spacing: 8) {
                    Text("解锁新成就")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Selge.Palette.textTertiary)
                    HStack(spacing: 12) {
                        ForEach(result.newAchievements) { def in
                            VStack(spacing: 4) {
                                Text(def.icon).font(.system(size: 26))
                                Text(def.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Selge.Palette.textSecondary)
                            }
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .selgeCard()
            }

            Spacer()
            mainButton(title: "完成", icon: "checkmark") { dismiss() }
        }
    }

    private func summaryRow(label: String, value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Selge.Palette.textTertiary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(highlight ? Selge.Palette.accent : Selge.Palette.textPrimary)
        }
    }

    // MARK: 通用

    private func mainButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Selge.accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.bottom, 10)
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded())
        return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }

    private func finish() {
        let result: SettlementResult
        switch category.kind {
        case .time:
            let start = startedAt ?? Date.now
            result = store.settle(category: category, startedAt: start, endedAt: Date.now)
        case .once:
            result = store.settleOnce(category: category)
        }
        phase = .summary(result)
    }
}
