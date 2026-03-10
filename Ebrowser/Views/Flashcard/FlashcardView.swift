import SwiftUI

/// 個別フラッシュカードビュー（Phase 5 で本実装）
struct FlashcardView: View {
    var body: some View {
        ContentUnavailableView(
            "カード",
            systemImage: "rectangle.portrait",
            description: Text("Phase 5 で実装予定")
        )
    }
}

#Preview {
    FlashcardView()
}
