import Foundation
import SwiftData

/// 閲覧履歴モデル
@Model
final class BrowsingHistory {
    var title: String
    var url: String
    var visitedAt: Date

    init(title: String, url: String) {
        self.title = title
        self.url = url
        self.visitedAt = Date()
    }
}
