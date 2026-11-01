import SwiftUI
import SwiftData

/// 单条历险记录内容（原生列表行样式）
struct RecordRow: View {
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

struct RecordEditorView: View {
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
