import SwiftUI
import SwiftData

/// 単語を保存するフォルダを選択するビュー
struct FolderPickerView: View {

    let result: DictionaryResult
    var onSelect: (WordFolder?) -> Void

    @Query(sort: \WordFolder.createdAt) private var folders: [WordFolder]
    @Environment(\.dismiss) private var dismiss

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
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
