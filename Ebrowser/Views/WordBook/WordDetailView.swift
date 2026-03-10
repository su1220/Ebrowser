import SwiftUI

/// 単語の詳細表示ビュー
struct WordDetailView: View {

    @Bindable var word: SavedWord

    @Environment(AppViewModel.self) private var appViewModel
    private let speechService = SpeechService()
    @State private var showCopiedFeedback = false
    /// 長押しで選択された単語（nilでシートを閉じる）
    @State private var lookupWord: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // 見出し語 + 品詞バッジ + 発音ボタン
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(word.word)
                            .font(.title2.bold())
                        Text(word.partOfSpeech)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.blue.opacity(0.8)))
                    }
                    Spacer()
                    Button {
                        speechService.speak(word: word.word, audioURL: word.audioURL)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.blue.opacity(0.1)))
                    }
                }

                Divider()

                // Definition（長押しで単語検索）
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label("Definition", systemImage: "text.alignleft")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Spacer()
                        speakButton { speechService.speakText(word.definition) }
                    }
                    LongPressTextView(
                        text: word.definition,
                        font: .preferredFont(forTextStyle: .body),
                        textColor: .label
                    ) { tapped in lookupWord = tapped }
                }

                // Example（長押しで単語検索・あれば）
                if !word.example.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label("Example", systemImage: "quote.opening")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Spacer()
                            speakButton { speechService.speakText(word.example) }
                        }
                        LongPressTextView(
                            text: word.example,
                            font: UIFont(descriptor:
                                UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
                                    .withSymbolicTraits(.traitItalic)
                                    ?? .preferredFontDescriptor(withTextStyle: .body),
                                size: 0),
                            textColor: .secondaryLabel
                        ) { tapped in lookupWord = tapped }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                }

                // メモ欄
                memoSection

                // Source URL（あれば）
                if let sourceURL = word.sourceURL, !sourceURL.isEmpty {
                    sourceSection(urlString: sourceURL)
                }

                // 登録日
                HStack {
                    Spacer()
                    Text("Saved: \(word.savedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(20)
        }
        .navigationTitle(word.word)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { copyToClipboard() } label: {
                    Label(
                        showCopiedFeedback ? "コピー済み" : "コピー",
                        systemImage: showCopiedFeedback ? "checkmark" : "doc.on.doc"
                    )
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showCopiedFeedback {
                copiedToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 20)
            }
        }
        .animation(.spring(duration: 0.3), value: showCopiedFeedback)
        // 長押し単語の解説シート
        .sheet(item: $lookupWord) { w in
            WordDefinitionSheet(initialWord: w)
        }
    }

    // MARK: - メモセクション

    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "pencil")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            // 編集可能なメモ欄
            TextEditor(text: $word.memo)
                .font(.body)
                .frame(minHeight: 80)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                )

            // メモ内 URL の抽出・リンク表示
            let urls = extractURLs(from: word.memo)
            if !urls.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Links in Notes", systemImage: "link")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ForEach(urls, id: \.absoluteString) { url in
                        Button {
                            appViewModel.openInBrowser(url: url)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                                Text(url.absoluteString)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(.blue)
                        }
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
            }
        }
    }

    // MARK: - Source セクション

    private func sourceSection(urlString: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Source", systemImage: "safari")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Button {
                if let url = URL(string: urlString) {
                    appViewModel.openInBrowser(url: url)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                    Text(urlString)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundStyle(.blue)
            }
        }
    }

    // MARK: - 共通読み上げボタン

    private func speakButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.caption)
                .foregroundStyle(.blue)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.blue.opacity(0.12)))
        }
    }

    // MARK: - URL 抽出（NSDataDetector）

    private func extractURLs(from text: String) -> [URL] {
        guard !text.isEmpty,
              let detector = try? NSDataDetector(
                types: NSTextCheckingResult.CheckingType.link.rawValue
              ) else { return [] }

        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, range: range)
        return matches.compactMap { $0.url }
    }

    // MARK: - クリップボードコピー

    private func copyToClipboard() {
        let text = """
        [Word] \(word.word) (\(word.partOfSpeech))
        [Definition] \(word.definition)
        [Example] \(word.example)
        """
        UIPasteboard.general.string = text
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        showCopiedFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showCopiedFeedback = false
        }
    }

    private var copiedToast: some View {
        Label("クリップボードにコピーしました", systemImage: "checkmark.circle.fill")
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.green.opacity(0.85)))
    }
}

#Preview {
    NavigationStack {
        WordDetailView(word: SavedWord(
            word: "ubiquitous",
            partOfSpeech: "adjective",
            definition: "Present, appearing, or found everywhere.",
            example: "His ubiquitous influence was felt by all.",
            sourceURL: "https://www.example.com"
        ))
    }
    .modelContainer(for: SavedWord.self, inMemory: true)
    .environment(AppViewModel())
}
