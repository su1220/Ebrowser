import SwiftUI

/// 単語詳細ビュー（Phase 4 で本実装）
struct WordDetailView: View {
    var body: some View {
        ContentUnavailableView(
            "単語詳細",
            systemImage: "text.magnifyingglass",
            description: Text("Phase 4 で実装予定")
        )
    }
}

#Preview {
    WordDetailView()
}
