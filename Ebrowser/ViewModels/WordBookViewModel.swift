import Foundation
import Observation

/// 単語帳の状態管理ViewModel（Phase 4 で本実装）
@Observable
final class WordBookViewModel {
    var selectedFolder: WordFolder?
    var isShowingAddFolder: Bool = false
}
