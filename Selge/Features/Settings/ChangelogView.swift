import SwiftUI

/// 更新日志：读取随构建打包的 docs/CHANGELOG.md（由 release-please 生成，
/// 与 GitHub Release 版本一一对应），每个版本仅保留最重要的前几条。
struct ChangelogView: View {
    private let entries: [ChangelogParser.Entry]

    init() {
        entries = ChangelogParser.bundledEntries()
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 32))
                            .foregroundStyle(Selge.Palette.textTertiary)
                        Text("暂无更新日志")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Selge.Palette.textSecondary)
                        Text("当前版本 \(VersionInfo.shortVersion) · 首个版本")
                            .font(.system(size: 12))
                            .foregroundStyle(Selge.Palette.textTertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(entries) { entry in
                        entrySection(entry)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("更新日志")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func entrySection(_ entry: ChangelogParser.Entry) -> some View {
        Section {
            ForEach(entry.bullets.indices, id: \.self) { index in
                Text(entry.bullets[index])
                    .font(.system(size: 13))
                    .foregroundStyle(Selge.Palette.textSecondary)
            }
        } header: {
            HStack {
                Text("v\(entry.version)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Selge.Palette.accent)
                Spacer()
                Text(entry.date)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Selge.Palette.textTertiary)
            }
        }
    }
}
