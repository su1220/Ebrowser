import Foundation
import Observation
import SwiftData

/// ブラウザの状態を管理するViewModel
@Observable
final class BrowserViewModel {

    // MARK: - ナビゲーション状態
    var currentURL: URL? = URL(string: Constants.Browser.homeURL)
    var addressText: String = Constants.Browser.homeURL
    var pageTitle: String = ""

    // MARK: - ローディング状態
    var isLoading: Bool = false
    var loadingProgress: Double = 0.0

    // MARK: - ナビゲーションボタン有効状態
    var canGoBack: Bool = false
    var canGoForward: Bool = false

    // MARK: - ブックマーク状態
    var isBookmarked: Bool = false

    // MARK: - WebView操作トリガー（Coordinatorへの指令用）
    var navigationRequest: NavigationRequest?

    // MARK: - アドレスバーの入力をURLまたは検索クエリに変換してナビゲートする
    func navigate(to input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let url: URL
        if let directURL = makeURL(from: trimmed) {
            url = directURL
        } else {
            // URLでなければGoogle検索
            let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
            url = URL(string: Constants.Search.googleBaseURL + encoded)!
        }

        currentURL = url
        addressText = url.absoluteString
        navigationRequest = .load(url)
    }

    /// 戻る
    func goBack() {
        navigationRequest = .back
    }

    /// 進む
    func goForward() {
        navigationRequest = .forward
    }

    /// リロード
    func reload() {
        navigationRequest = .reload
    }

    // MARK: - ブックマーク登録確認
    func checkIsBookmarked(bookmarks: [Bookmark]) {
        guard let urlString = currentURL?.absoluteString else {
            isBookmarked = false
            return
        }
        isBookmarked = bookmarks.contains { $0.url == urlString }
    }

    // MARK: - Private

    /// 文字列からURLを生成する（http/httpsなければhttpsを付与）
    private func makeURL(from string: String) -> URL? {
        if string.hasPrefix("http://") || string.hasPrefix("https://") {
            return URL(string: string)
        }
        // ドット区切りでスペースなし → URLとみなす
        if string.contains(".") && !string.contains(" ") {
            return URL(string: "https://" + string)
        }
        return nil
    }
}

/// WebViewへのナビゲーション指令
enum NavigationRequest: Equatable {
    case load(URL)
    case back
    case forward
    case reload
}
