import SwiftUI
import SwiftData

/// 単語解説ボトムシート
/// NavigationStack で Definition・Example 内の単語をネスト検索できる
struct WordDefinitionSheet: View {

    /// 最初に検索する単語
    let initialWord: String
    var sourceURL: String?

    /// ネスト遷移用パス（同じ単語の重複プッシュを防ぐため Set で管理）
    @State private var navigationPath = NavigationPath()
    @State private var pushedWords: Set<String> = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            WordDefinitionContentView(
                word: initialWord,
                sourceURL: sourceURL,
                onWordLongPressed: { word in
                    pushWord(word)
                }
            )
            // String を受け取って新しい定義画面へ遷移
            .navigationDestination(for: String.self) { word in
                WordDefinitionContentView(
                    word: word,
                    sourceURL: sourceURL,
                    onWordLongPressed: { nextWord in
                        pushWord(nextWord)
                    }
                )
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    /// 重複を防いで NavigationPath に単語を追加する
    private func pushWord(_ word: String) {
        let lower = word.lowercased()
        // 現在表示中の単語と同じなら無視
        guard lower != initialWord.lowercased(),
              !pushedWords.contains(lower) else { return }
        pushedWords.insert(lower)
        navigationPath.append(word)
    }
}
