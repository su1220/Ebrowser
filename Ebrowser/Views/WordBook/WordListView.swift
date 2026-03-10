import SwiftUI
import SwiftData

/// フォルダ内（またはすべて）の単語一覧ビュー
struct WordListView: View {

    var folder: WordFolder?
    var title: String

    @Query(sort: \SavedWord.savedAt, order: .reverse) private var allWords: [SavedWord]
    @Query(sort: \WordFolder.createdAt) private var folders: [WordFolder]
    @Environment(\.modelContext) private var modelContext

    /// 表示対象の単語（フォルダ指定あり／なし で絞り込み）
    private var words: [SavedWord] {
        if let folder {
            return allWords.filter {
                $0.folder?.persistentModelID == folder.persistentModelID
            }
        }
        return allWords
    }

    var body: some View {
        Group {
            if words.isEmpty {
                ContentUnavailableView(
                    "単語がありません",
                    systemImage: "text.magnifyingglass",
                    description: Text("ブラウザで英単語を長押しして登録しましょう")
                )
            } else {
                List {
                    ForEach(words) { word in
                        NavigationLink {
                            WordDetailView(word: word)
                        } label: {
                            wordRow(word)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(word)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            // フォルダ間移動メニュー
                            Menu {
                                // Unfiled へ移動
                                Button {
                                    word.folder = nil
                                } label: {
                                    Label("Unfiled", systemImage: "tray")
                                }
                                // 各フォルダへ移動
                                ForEach(folders) { target in
                                    // 現在のフォルダは除外
                                    if target.persistentModelID != folder?.persistentModelID {
                                        Button {
                                            word.folder = target
                                        } label: {
                                            Label(target.name, systemImage: "folder")
                                        }
                                    }
                                }
                            } label: {
                                Label("フォルダに移動", systemImage: "folder.badge.arrow.up")
                            }

                            Divider()

                            Button(role: .destructive) {
                                modelContext.delete(word)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 単語セル

    private func wordRow(_ word: SavedWord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(word.word)
                    .font(.body.bold())
                Text(word.partOfSpeech)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.blue.opacity(0.8)))
            }
            Text(word.definition)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        WordListView(folder: nil, title: "すべての単語")
    }
    .modelContainer(for: [WordFolder.self, SavedWord.self], inMemory: true)
}
