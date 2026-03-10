import SwiftUI
import UIKit

/// 長押しで単語を検出できる UITextView の SwiftUI ラッパー
struct LongPressTextView: UIViewRepresentable {

    let text: String
    let font: UIFont
    let textColor: UIColor
    var onWordLongPressed: (String) -> Void

    func makeUIView(context: Context) -> AutoSizingTextView {
        let textView = AutoSizingTextView()
        textView.isEditable = false
        textView.isScrollEnabled = false   // 親 ScrollView へスクロール委譲
        textView.isSelectable = false      // デフォルトの選択 UI を非表示
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0

        // 長押しジェスチャーを登録
        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPress.minimumPressDuration = 0.5
        textView.addGestureRecognizer(longPress)

        return textView
    }

    func updateUIView(_ textView: AutoSizingTextView, context: Context) {
        textView.text = text
        textView.font = font
        textView.textColor = textColor
        // テキスト変更後に intrinsicContentSize を再計算させる
        textView.invalidateIntrinsicContentSize()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onWordLongPressed: onWordLongPressed)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject {
        var onWordLongPressed: (String) -> Void

        init(onWordLongPressed: @escaping (String) -> Void) {
            self.onWordLongPressed = onWordLongPressed
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began,
                  let textView = gesture.view as? UITextView else { return }

            let point = gesture.location(in: textView)

            // タップ位置の文字オフセットを取得（isSelectable=false でも動作）
            guard let position = textView.closestPosition(to: point) else { return }
            let offset = textView.offset(from: textView.beginningOfDocument, to: position)

            guard let text = textView.text,
                  let word = extractWord(at: offset, from: text),
                  !word.isEmpty else { return }

            onWordLongPressed(word)
        }

        /// 文字列中の指定オフセット位置にある英単語を抽出する
        private func extractWord(at offset: Int, from text: String) -> String? {
            let chars = Array(text)
            guard offset >= 0, offset < chars.count else { return nil }

            let ch = chars[offset]
            guard ch.isLetter || ch == "'" || ch == "-" else { return nil }

            // 単語の開始位置を探す
            var start = offset
            while start > 0 {
                let prev = chars[start - 1]
                if prev.isLetter || prev == "'" || prev == "-" { start -= 1 } else { break }
            }

            // 単語の終了位置を探す
            var end = offset
            while end < chars.count {
                let curr = chars[end]
                if curr.isLetter || curr == "'" || curr == "-" { end += 1 } else { break }
            }

            let word = String(chars[start..<end])

            // アルファベットを最低1文字含む単語のみ返す
            guard word.contains(where: { $0.isLetter }) else { return nil }
            return word
        }
    }
}

// MARK: - AutoSizingTextView

/// intrinsicContentSize を内容に合わせて自動調整する UITextView サブクラス
final class AutoSizingTextView: UITextView {

    override func layoutSubviews() {
        super.layoutSubviews()
        // レイアウト更新のたびに intrinsicContentSize を再計算させる
        // NavigationStack プッシュ後など bounds.width が 0 → 正値に変わるタイミングで確実に再計算される
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        // bounds.width が 0 の初期状態は画面幅をフォールバックとして使用
        let width = bounds.width > 0
            ? bounds.width
            : UIScreen.main.bounds.width - 40   // 左右パディング分を引く
        return sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    }
}
