import Foundation

/// Free Dictionary API のレスポンスモデル
struct DictionaryResponse: Codable {
    let word: String
    let phonetics: [Phonetic]
    let meanings: [Meaning]
}

struct Phonetic: Codable {
    let text: String?
    let audio: String?
}

struct Meaning: Codable {
    let partOfSpeech: String
    let definitions: [Definition]
}

struct Definition: Codable {
    let definition: String
    let example: String?
}

/// Free Dictionary API から単語情報を取得するサービス（Phase 3 で本実装）
final class DictionaryService {

    /// 単語を検索して最初のヒット結果を返す
    func lookup(word: String) async throws -> DictionaryResult {
        let encodedWord = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? word
        let urlString = Constants.API.dictionaryBaseURL + encodedWord
        guard let url = URL(string: urlString) else {
            throw DictionaryError.invalidWord
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DictionaryError.networkError
        }

        switch httpResponse.statusCode {
        case 200:
            let entries = try JSONDecoder().decode([DictionaryResponse].self, from: data)
            return try parse(entries: entries, originalWord: word)
        case 404:
            throw DictionaryError.wordNotFound(word)
        default:
            throw DictionaryError.networkError
        }
    }

    /// APIレスポンスから必要な情報を抽出する
    private func parse(entries: [DictionaryResponse], originalWord: String) throws -> DictionaryResult {
        guard let entry = entries.first else {
            throw DictionaryError.wordNotFound(originalWord)
        }

        // 最初の意味・定義・例文を取得
        guard let meaning = entry.meanings.first,
              let definition = meaning.definitions.first else {
            throw DictionaryError.wordNotFound(originalWord)
        }

        // 音声URLは空文字を除外して最初のものを使用
        let audioURL = entry.phonetics
            .compactMap { $0.audio }
            .first { !$0.isEmpty }

        return DictionaryResult(
            word: entry.word,
            partOfSpeech: meaning.partOfSpeech,
            definition: definition.definition,
            example: definition.example ?? "",
            audioURL: audioURL
        )
    }
}

/// 辞書検索結果
struct DictionaryResult {
    let word: String
    let partOfSpeech: String
    let definition: String
    let example: String
    let audioURL: String?
}

/// 辞書サービスのエラー定義
enum DictionaryError: LocalizedError {
    case invalidWord
    case wordNotFound(String)
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidWord:
            return "Invalid word"
        case .wordNotFound(let word):
            return "\"\(word)\" was not found in the dictionary."
        case .networkError:
            return "Network error. Please check your connection."
        }
    }
}
