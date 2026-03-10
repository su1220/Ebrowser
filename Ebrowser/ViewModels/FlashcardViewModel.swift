import Foundation
import Observation

/// フラッシュカードの状態管理ViewModel（Phase 5 で本実装）
@Observable
final class FlashcardViewModel {
    var cards: [SavedWord] = []
    var currentIndex: Int = 0
    var isFlipped: Bool = false
    var isSessionComplete: Bool = false

    /// 現在のカードを返す
    var currentCard: SavedWord? {
        guard !cards.isEmpty, currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }
}
