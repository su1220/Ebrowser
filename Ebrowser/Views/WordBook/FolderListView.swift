import SwiftUI
import SwiftData

/// 単語帳タブのトップ画面：フォルダ一覧
struct FolderListView: View {

    @Query(sort: \WordFolder.createdAt) private var folders: [WordFolder]
    @Query(sort: \SavedWord.savedAt, order: .reverse) private var allWords: [SavedWord]
    @Environment(\.modelContext) private var modelContext

    @State private var showNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var renameTarget: WordFolder? = nil
    @State private var renameText = ""

    var body: some View {
        NavigationStack {
            List {
                // すべての単語
                NavigationLink {
                    WordListView(folder: nil, title: "すべての単語")
                } label: {
                    HStack {
                        Label("すべての単語", systemImage: "tray.full")
                        Spacer()
                        Text("\(allWords.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // フォルダ一覧
                if !folders.isEmpty {
                    Section("フォルダ") {
                        ForEach(folders) { folder in
                            NavigationLink {
                                WordListView(folder: folder, title: folder.name)
                            } label: {
                                HStack {
                                    Label(folder.name, systemImage: "folder")
                                    Spacer()
                                    Text("\(folder.words.count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .contextMenu {
                                // リネーム
                                Button {
                                    renameText = folder.name
                                    renameTarget = folder
                                } label: {
                                    Label("名前を変更", systemImage: "pencil")
                                }
                                // 削除
                                Button(role: .destructive) {
                                    deleteFolder(folder)
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteFolder(folder)
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("単語帳")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newFolderName = ""
                        showNewFolderAlert = true
                    } label: {
                        Label("新規フォルダ", systemImage: "folder.badge.plus")
                    }
                }
            }
            // 新規フォルダ作成アラート
            .alert("新規フォルダ", isPresented: $showNewFolderAlert) {
                TextField("フォルダ名", text: $newFolderName)
                Button("作成") { createFolder(name: newFolderName) }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("新しいフォルダの名前を入力してください")
            }
            // リネームアラート
            .alert("名前を変更", isPresented: Binding(
                get: { renameTarget != nil },
                set: { if !$0 { renameTarget = nil } }
            )) {
                TextField("フォルダ名", text: $renameText)
                Button("変更") {
                    if let folder = renameTarget {
                        renameFolder(folder, to: renameText)
                    }
                }
                Button("キャンセル", role: .cancel) { renameTarget = nil }
            } message: {
                Text("新しいフォルダ名を入力してください")
            }
            // 空状態
            .overlay {
                if folders.isEmpty && allWords.isEmpty {
                    ContentUnavailableView(
                        "単語がありません",
                        systemImage: "book",
                        description: Text("ブラウザで英単語を長押しして登録しましょう")
                    )
                }
            }
        }
    }

    // MARK: - 操作

    private func createFolder(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        modelContext.insert(WordFolder(name: trimmed))
    }

    private func renameFolder(_ folder: WordFolder, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        folder.name = trimmed
        renameTarget = nil
    }

    private func deleteFolder(_ folder: WordFolder) {
        // フォルダ削除時、所属単語は Unfiled（folder = nil）に移動
        for word in folder.words {
            word.folder = nil
        }
        modelContext.delete(folder)
    }
}

#Preview {
    FolderListView()
        .modelContainer(for: [WordFolder.self, SavedWord.self], inMemory: true)
}
