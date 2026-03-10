import Foundation

/// .sheet(item:) で String を直接使えるようにする拡張
extension String: @retroactive Identifiable {
    public var id: String { self }
}

/// アプリ全体で使用する定数
enum Constants {

    /// Free Dictionary API
    enum API {
        static let dictionaryBaseURL = "https://api.dictionaryapi.dev/api/v2/entries/en/"
    }

    /// 検索エンジン
    enum Search {
        static let googleBaseURL = "https://www.google.com/search?q="
    }

    /// デフォルトページ
    enum Browser {
        static let homeURL = "https://www.google.com"
    }

    /// iCloud コンテナ識別子（Phase 6 で使用）
    enum CloudKit {
        static let containerIdentifier = "iCloud.com.ebrowser.app"
    }
}
