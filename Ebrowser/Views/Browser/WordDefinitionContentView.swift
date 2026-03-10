import SwiftUI
import SwiftData

/// 単語定義コンテンツビュー
/// WordDefinitionSheet のルートと、ナビゲーションでプッシュされた画面の両方で使用する
struct WordDefinitionContentView: View {

    let word: String
    var sourceURL: String?
    /// 単語が長押しされたときの通知（NavigationPath への追加を親が行う）
    var onWordLongPressed: (String) -> Void

    @State private var vm = WordDefinitionViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showFolderPicker = false
    @State private var showSaveSuccess = false
    @State private var savedFolderName = ""

    var body: some View {
        Group {
            if vm.isLoading {
                loadingView
            } else if let message = vm.errorMessage {
                errorView(message: message)
            } else if let result = vm.result {
                definitionView(result: result)
            } else {
                Color.clear
            }
        }
        .navigationTitle(vm.selectedWord.isEmpty ? word : vm.selectedWord)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFolderPicker = true
                } label: {
                    Label("単語帳に追加", systemImage: "plus.circle")
                }
                .disabled(vm.result == nil)
            }
        }
        .onAppear {
            // 未検索の場合のみ lookup を実行（NavigationStack で再表示されても二重検索しない）
            if vm.selectedWord.isEmpty {
                vm.lookup(word: word)
            }
        }
        .sheet(isPresented: $showFolderPicker) {
            if let result = vm.result {
                FolderPickerView(result: result) { folder in
                    saveWord(result: result, to: folder)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showSaveSuccess {
                saveSuccessToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 16)
            }
        }
        .animation(.spring(duration: 0.3), value: showSaveSuccess)
    }

    // MARK: - ローディング

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
            Text("Looking up \"\(word)\"...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - エラー

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 解説表示

    private func definitionView(result: DictionaryResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // 見出し語 + 品詞バッジ + 発音ボタン
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.word)
                            .font(.title2.bold())
                        Text(result.partOfSpeech)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.blue.opacity(0.8)))
                    }
                    Spacer()
                    Button { vm.speak() } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.blue.opacity(0.1)))
                    }
                }

                Divider()

                // Definition（長押し対応テキスト）
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label("Definition", systemImage: "text.alignleft")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Spacer()
                        speakButton { vm.speakText(result.definition) }
                    }
                    LongPressTextView(
                        text: result.definition,
                        font: .preferredFont(forTextStyle: .body),
                        textColor: .label,
                        onWordLongPressed: onWordLongPressed
                    )
                }

                // Example（長押し対応テキスト・あれば）
                if !result.example.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label("Example", systemImage: "quote.opening")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Spacer()
                            speakButton { vm.speakText(result.example) }
                        }
                        LongPressTextView(
                            text: result.example,
                            font: UIFont(descriptor:
                                UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
                                    .withSymbolicTraits(.traitItalic) ?? .preferredFontDescriptor(withTextStyle: .body),
                                size: 0),
                            textColor: .secondaryLabel,
                            onWordLongPressed: onWordLongPressed
                        )
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
            }
            .padding(20)
        }
    }

    // MARK: - 読み上げボタン（共通）

    private func speakButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.caption)
                .foregroundStyle(.blue)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.blue.opacity(0.12)))
        }
    }

    // MARK: - 保存完了トースト

    private var saveSuccessToast: some View {
        Label(
            savedFolderName.isEmpty ? "Saved to Word Book" : "Saved to \"\(savedFolderName)\"",
            systemImage: "checkmark.circle.fill"
        )
        .font(.subheadline)
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(Color.green.opacity(0.85)))
    }

    // MARK: - 保存処理

    private func saveWord(result: DictionaryResult, to folder: WordFolder?) {
        let saved = SavedWord(
            word: result.word,
            partOfSpeech: result.partOfSpeech,
            definition: result.definition,
            example: result.example,
            audioURL: result.audioURL,
            sourceURL: sourceURL
        )
        saved.folder = folder
        modelContext.insert(saved)

        savedFolderName = folder?.name ?? ""
        showSaveSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showSaveSuccess = false
        }
    }
}
