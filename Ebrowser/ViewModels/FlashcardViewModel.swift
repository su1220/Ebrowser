import Foundation
import Observation
import SwiftUI

/// フラッシュカードセッションの状態を管理するViewModel
@Observable
final class FlashcardViewModel {

    // MARK: - セッション状態

    /// 学習対象カード
    var cards: [SavedWord] = []
    /// 現在表示中のインデックス
    var currentIndex: Int = 0
    /// カードが裏返し状態か
    var isFlipped: Bool = false
    /// セッション完了フラグ
    var isSessionComplete: Bool = false
    /// シャッフルモードか
    var isShuffled: Bool = false

    // MARK: - 計算プロパティ

    var currentCard: SavedWord? {
        guard !cards.isEmpty, currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    /// 進捗（0.0 〜 1.0）
    var progress: Double {
        guard !cards.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(cards.count)
    }

    var totalCount: Int { cards.count }
    var currentNumber: Int { currentIndex + 1 }

    // MARK: - セッション操作

    /// セッションを開始する
    func start(words: [SavedWord], shuffled: Bool) {
        isShuffled = shuffled
        cards = shuffled ? words.shuffled() : words
        currentIndex = 0
        isFlipped = false
        isSessionComplete = false
    }

    /// カードをめくる
    func flip() {
        withAnimation(.spring(duration: 0.45)) {
            isFlipped.toggle()
        }
    }

    /// 次のカードへ進む
    func next() {
        guard !cards.isEmpty else { return }

        if currentIndex + 1 >= cards.count {
            isSessionComplete = true
        } else {
            // 裏返しをリセットしてから次へ
            withAnimation(.easeOut(duration: 0.2)) {
                isFlipped = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.currentIndex += 1
            }
        }
    }

    /// もう一度同じカードセットで学習する
    func restart() {
        let words = isShuffled ? cards.shuffled() : cards
        start(words: words, shuffled: isShuffled)
    }
}
