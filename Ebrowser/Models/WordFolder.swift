import Foundation
import SwiftData

/// 単語帳のフォルダモデル
@Model
final class WordFolder {
    var name: String
    var createdAt: Date

    /// フォルダに属する単語リスト
    @Relationship(deleteRule: .cascade, inverse: \SavedWord.folder)
    var words: [SavedWord] = []

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}
