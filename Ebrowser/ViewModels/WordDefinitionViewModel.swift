import Foundation
import Observation

/// 単語解説シートの状態を管理するViewModel
@Observable
final class WordDefinitionViewModel {

    var selectedWord: String = ""
    var result: DictionaryResult? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var isShowingSheet: Bool = false

    private let dictionaryService = DictionaryService()
    private let speechService = SpeechService()

    /// 単語を検索してシートを表示する
    func lookup(word: String) {
        // アルファベット単語のみ対象（数字・記号は除外）
        let cleaned = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty,
              cleaned.range(of: "^[a-zA-Z'\\-]+$", options: .regularExpression) != nil else { return }

        selectedWord = cleaned
        result = nil
        errorMessage = nil
        isLoading = true
        isShowingSheet = true

        Task { @MainActor in
            do {
                result = try await dictionaryService.lookup(word: cleaned)
            } catch let error as DictionaryError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "Network error. Please check your connection."
            }
            isLoading = false
        }
    }

    /// 見出し語の発音を再生する（API音声URL優先、なければ合成音声）
    func speak() {
        speechService.speak(
            word: result?.word ?? selectedWord,
            audioURL: result?.audioURL
        )
    }

    /// 任意のテキストを合成音声で読み上げる（Definition・Example用）
    func speakText(_ text: String) {
        speechService.speak(word: text, audioURL: nil)
    }
}
