import SwiftUI
import SwiftData

/// 単語解説ボトムシート
struct WordDefinitionSheet: View {

    var viewModel: WordDefinitionViewModel
    var sourceURL: String?

    @Environment(\.modelContext) private var modelContext
    @State private var showFolderPicker = false
    @State private var showSaveSuccess = false
    @State private var savedFolderName: String = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let message = viewModel.errorMessage {
                    errorView(message: message)
                } else if let result = viewModel.result {
                    definitionView(result: result)
                }
            }
            .navigationTitle(viewModel.selectedWord)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 単語帳に追加ボタン
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFolderPicker = true
                    } label: {
                        Label("単語帳に追加", systemImage: "plus.circle")
                    }
                    .disabled(viewModel.result == nil)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        // フォルダ選択シート
        .sheet(isPresented: $showFolderPicker) {
            if let result = viewModel.result {
                FolderPickerView(result: result) { folder in
                    saveWord(result: result, to: folder)
                }
            }
        }
        // 保存完了トースト
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
            Text("Looking up \"\(viewModel.selectedWord)\"...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - エラー表示

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

                // 見出し語 + 品詞 + 発音ボタン
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
                    // 発音ボタン
                    Button {
                        viewModel.speak()
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.blue.opacity(0.1)))
                    }
                }

                Divider()

                // 英文解説
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label("Definition", systemImage: "text.alignleft")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Spacer()
                        speakButton { viewModel.speakText(result.definition) }
                    }
                    Text(result.definition)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // 例文（あれば）
                if !result.example.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label("Example", systemImage: "quote.opening")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Spacer()
                            speakButton { viewModel.speakText(result.example) }
                        }
                        Text(result.example)
                            .font(.body)
                            .italic()
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
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

    // MARK: - 共通読み上げボタン

    private func speakButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "speaker.wave.2")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color(.systemGray5)))
        }
    }

    // MARK: - 保存完了トースト

    private var saveSuccessToast: some View {
        Label(
            savedFolderName.isEmpty
                ? "Saved to Word Book"
                : "Saved to \"\(savedFolderName)\"",
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
        let word = SavedWord(
            word: result.word,
            partOfSpeech: result.partOfSpeech,
            definition: result.definition,
            example: result.example,
            audioURL: result.audioURL,
            sourceURL: sourceURL
        )
        word.folder = folder
        modelContext.insert(word)

        savedFolderName = folder?.name ?? ""
        showSaveSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showSaveSuccess = false
        }
    }
}
