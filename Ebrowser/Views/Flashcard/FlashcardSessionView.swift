import SwiftUI
import SwiftData

/// フラッシュカード学習タブのルートビュー
struct FlashcardSessionView: View {

    @Query(sort: \WordFolder.createdAt) private var folders: [WordFolder]
    @Query(sort: \SavedWord.savedAt, order: .reverse) private var allWords: [SavedWord]

    @State private var vm = FlashcardViewModel()
    @State private var isStarted = false

    // セットアップ画面の選択状態
    @State private var selectedFolderID: PersistentIdentifier? = nil  // nil = すべての単語
    @State private var isShuffled = true

    var body: some View {
        NavigationStack {
            Group {
                if !isStarted {
                    setupView
                } else if vm.isSessionComplete {
                    completeView
                } else {
                    sessionView
                }
            }
            .navigationTitle("学習")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - セットアップ画面

    private var setupView: some View {
        VStack(spacing: 0) {
            Form {
                // フォルダ選択
                Section("学習する単語") {
                    Picker("フォルダ", selection: $selectedFolderID) {
                        Text("すべての単語 (\(allWords.count)語)")
                            .tag(Optional<PersistentIdentifier>.none)
                        ForEach(folders) { folder in
                            Text("\(folder.name) (\(folder.words.count)語)")
                                .tag(Optional(folder.persistentModelID))
                        }
                    }
                }

                // オプション
                Section("オプション") {
                    Toggle("シャッフル", isOn: $isShuffled)
                }

                // 学習できる単語数の表示
                Section {
                    HStack {
                        Image(systemName: "rectangle.on.rectangle")
                            .foregroundStyle(.blue)
                        Text("学習枚数")
                        Spacer()
                        Text("\(targetWords.count)枚")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // 学習開始ボタン
            Button {
                startSession()
            } label: {
                Text("学習を開始")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(targetWords.isEmpty ? Color.gray : Color.blue)
                    )
            }
            .disabled(targetWords.isEmpty)
            .padding()
        }
    }

    // MARK: - 学習中画面

    private var sessionView: some View {
        VStack(spacing: 20) {

            // 進捗バー + カウンター
            VStack(spacing: 6) {
                HStack {
                    Text("\(vm.currentNumber) / \(vm.totalCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("終了") {
                        isStarted = false
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }
                ProgressView(value: vm.progress)
                    .tint(.blue)
            }
            .padding(.horizontal)

            // フラッシュカード（タップでめくり・左スワイプで次へ）
            if let card = vm.currentCard {
                FlashcardView(
                    word: card,
                    isFlipped: vm.isFlipped
                ) {
                    vm.flip()
                }
                .padding(.horizontal)
                .gesture(
                    DragGesture(minimumDistance: 40, coordinateSpace: .local)
                        .onEnded { value in
                            // 左スワイプで次のカードへ
                            if value.translation.width < -40 {
                                vm.next()
                            }
                        }
                )
            }

            Spacer()

            // スワイプ操作ヒント
            HStack(spacing: 16) {
                Label("左スワイプで次へ", systemImage: "arrow.left.to.line")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.secondary)
                Label("タップでめくる", systemImage: "hand.tap")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom)
        }
        .padding(.top)
    }

    // MARK: - 完了画面

    private var completeView: some View {
        VStack(spacing: 32) {
            Spacer()

            // 完了アイコン
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("学習完了！")
                    .font(.title.bold())
                Text("\(vm.totalCount)枚のカードを学習しました")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 12) {
                // もう一度
                Button {
                    vm.restart()
                } label: {
                    Label("もう一度学習する", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue))
                }

                // 単語帳に戻る
                Button {
                    isStarted = false
                } label: {
                    Label("設定に戻る", systemImage: "list.bullet")
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.blue, lineWidth: 1.5)
                        )
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - ヘルパー

    /// 選択フォルダに対応する学習対象単語
    private var targetWords: [SavedWord] {
        if let id = selectedFolderID {
            return allWords.filter { $0.folder?.persistentModelID == id }
        }
        return allWords
    }

    private func startSession() {
        vm.start(words: targetWords, shuffled: isShuffled)
        isStarted = true
    }
}

#Preview {
    FlashcardSessionView()
        .modelContainer(for: [WordFolder.self, SavedWord.self], inMemory: true)
}
