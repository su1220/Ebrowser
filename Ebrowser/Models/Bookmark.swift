import Foundation
import SwiftData

/// ブックマークモデル
@Model
final class Bookmark {
    var title: String
    var url: String
    var savedAt: Date

    init(title: String, url: String) {
        self.title = title
        self.url = url
        self.savedAt = Date()
    }
}
