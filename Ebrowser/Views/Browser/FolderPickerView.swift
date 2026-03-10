import SwiftUI
import SwiftData

/// 単語を保存するフォルダを選択するビュー
struct FolderPickerView: View {

    let result: DictionaryResult
    var onSelect: (WordFolder?) -> Void

    @Query(sort: \WordFolder.createdAt) private var folders: [WordFolder]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showNewFolderAlert = false
    @State private var newFolderName = ""

    var body: some View {
        NavigationStack {
            List {
                // 未分類（フォルダなし）
                Button {
                    onSelect(nil)
                    dismiss()
                } label: {
                    Label("Unfiled", systemImage: "tray")
                        .foregroundStyle(.primary)
                }

                // 既存フォルダ一覧
                ForEach(folders) { folder in
                    Button {
                        onSelect(folder)
                        dismiss()
                    } label: {
                        Label(folder.name, systemImage: "folder")
                            .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("フォルダを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newFolderName = ""
                        showNewFolderAlert = true
                    } label: {
                        Label("新規フォルダ", systemImage: "folder.badge.plus")
                    }
                }
            }
            .alert("新規フォルダ", isPresented: $showNewFolderAlert) {
                TextField("フォルダ名", text: $newFolderName)
                Button("作成") { createFolder() }
                    .disabled(newFolderName.trimmingCharacters(in: .whitespaces).isEmpty)
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("新しいフォルダの名前を入力してください")
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func createFolder() {
        let name = newFolderName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let folder = WordFolder(name: name)
        modelContext.insert(folder)
    }
}
