import SwiftUI

/// フラッシュカード学習セッションのプレースホルダービュー（Phase 5 で本実装）
struct FlashcardSessionView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "フラッシュカード",
                systemImage: "rectangle.on.rectangle",
                description: Text("Phase 5 で実装予定")
            )
            .navigationTitle("学習")
        }
    }
}

#Preview {
    FlashcardSessionView()
}
