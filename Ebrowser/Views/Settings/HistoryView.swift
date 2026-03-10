import SwiftUI
import SwiftData

/// 閲覧履歴一覧ビュー
struct HistoryView: View {

    @Query(sort: \BrowsingHistory.visitedAt, order: .reverse) private var histories: [BrowsingHistory]
    @Environment(\.modelContext) private var modelContext

    @State private var showDeleteConfirm = false

    /// 履歴をタップした時のコールバック（BrowserViewへURL渡し）
    var onSelect: ((URL) -> Void)?

    var body: some View {
        Group {
            if histories.isEmpty {
                ContentUnavailableView(
                    "閲覧履歴がありません",
                    systemImage: "clock",
                    description: Text("ページを訪問すると自動的に記録されます")
                )
            } else {
                List {
                    ForEach(histories) { history in
                        Button {
                            if let url = URL(string: history.url) {
                                onSelect?(url)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(history.title)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                HStack {
                                    Text(history.url)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(history.visitedAt, style: .relative)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteHistories)
                }
            }
        }
        .navigationTitle("閲覧履歴")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !histories.isEmpty {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Text("すべて削除")
                        .foregroundStyle(.red)
                }
            }
        }
        .confirmationDialog(
            "閲覧履歴をすべて削除しますか？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("すべて削除", role: .destructive) {
                deleteAllHistories()
            }
            Button("キャンセル", role: .cancel) {}
        }
    }

    private func deleteHistories(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(histories[index])
        }
    }

    private func deleteAllHistories() {
        for history in histories {
            modelContext.delete(history)
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: BrowsingHistory.self, inMemory: true)
}
