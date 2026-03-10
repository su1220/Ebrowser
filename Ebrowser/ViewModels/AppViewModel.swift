import Foundation
import Observation

/// タブ定義
enum AppTab: Int {
    case browser = 0
    case wordBook = 1
    case flashcard = 2
    case settings = 3
}

/// アプリ全体の共有状態（タブ間通信に使用）
@Observable
final class AppViewModel {

    /// 現在選択中のタブ
    var selectedTab: AppTab = .browser

    /// ブラウザタブへ渡す遷移先URL（ブックマーク・履歴からのジャンプ用）
    var pendingURL: URL? = nil

    /// ブラウザタブに遷移してURLを開く
    func openInBrowser(url: URL) {
        pendingURL = url
        selectedTab = .browser
    }
}
