import SwiftUI

/// 単語帳フォルダ一覧のプレースホルダービュー（Phase 4 で本実装）
struct FolderListView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "単語帳",
                systemImage: "book.fill",
                description: Text("Phase 4 で実装予定")
            )
            .navigationTitle("単語帳")
        }
    }
}

#Preview {
    FolderListView()
}
