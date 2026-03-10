import SwiftUI
import SwiftData

/// ブックマーク一覧・管理ビュー
struct BookmarkView: View {

    @Query(sort: \Bookmark.savedAt, order: .reverse) private var bookmarks: [Bookmark]
    @Environment(\.modelContext) private var modelContext

    /// ブックマークをタップした時のコールバック（BrowserViewへURL渡し）
    var onSelect: ((URL) -> Void)?

    var body: some View {
        Group {
            if bookmarks.isEmpty {
                ContentUnavailableView(
                    "ブックマークがありません",
                    systemImage: "bookmark",
                    description: Text("ブラウザ上部のブックマークボタンで登録できます")
                )
            } else {
                List {
                    ForEach(bookmarks) { bookmark in
                        Button {
                            if let url = URL(string: bookmark.url) {
                                onSelect?(url)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(bookmark.title)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Text(bookmark.url)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .onDelete(perform: deleteBookmarks)
                }
            }
        }
        .navigationTitle("ブックマーク")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !bookmarks.isEmpty {
                EditButton()
            }
        }
    }

    private func deleteBookmarks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(bookmarks[index])
        }
    }
}

#Preview {
    NavigationStack {
        BookmarkView()
    }
    .modelContainer(for: Bookmark.self, inMemory: true)
}
