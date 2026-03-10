import SwiftUI

/// フォルダ内の単語一覧ビュー（Phase 4 で本実装）
struct WordListView: View {
    var body: some View {
        ContentUnavailableView(
            "単語一覧",
            systemImage: "list.bullet",
            description: Text("Phase 4 で実装予定")
        )
    }
}

#Preview {
    WordListView()
}
