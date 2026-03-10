import Foundation
import SwiftData

/// 単語帳に保存された単語モデル
@Model
final class SavedWord {
    var word: String
    var partOfSpeech: String
    var definition: String      // 英文解説
    var example: String         // 英文例文
    var audioURL: String?       // 発音音声URL（Free Dictionary APIから取得）
    var savedAt: Date
    var sourceURL: String?      // 保存時に閲覧していたページのURL
    var memo: String = ""       // ユーザーメモ（自由記述・URL貼り付け可）

    /// 所属フォルダ（nilの場合は未分類）
    var folder: WordFolder?

    init(
        word: String,
        partOfSpeech: String,
        definition: String,
        example: String,
        audioURL: String? = nil,
        sourceURL: String? = nil
    ) {
        self.word = word
        self.partOfSpeech = partOfSpeech
        self.definition = definition
        self.example = example
        self.audioURL = audioURL
        self.savedAt = Date()
        self.sourceURL = sourceURL
    }
}
