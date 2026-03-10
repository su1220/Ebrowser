import SwiftUI

/// フリップアニメーション付きフラッシュカード
struct FlashcardView: View {

    let word: SavedWord
    let isFlipped: Bool
    var onTap: () -> Void

    private let speechService = SpeechService()

    var body: some View {
        ZStack {
            // 表面：見出し語 + 品詞 + 発音ボタン
            cardFront
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .opacity(isFlipped ? 0 : 1)

            // 裏面：英文解説 + 例文
            cardBack
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .opacity(isFlipped ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 260)
        .onTapGesture { onTap() }
    }

    // MARK: - 表面

    private var cardFront: some View {
        VStack(spacing: 0) {
            Spacer()

            // 単語 + 品詞バッジ
            VStack(spacing: 12) {
                Text(word.word)
                    .font(.system(size: 40, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(word.partOfSpeech)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.blue.opacity(0.8)))
            }

            Spacer()

            // 発声ボタン（「タップして定義を確認」の直上）
            Button {
                speechService.speak(word: word.word, audioURL: word.audioURL)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.blue.opacity(0.1)))
            }
            .padding(.bottom, 12)

            // タップヒント（目立つカプセルスタイル）
            HStack(spacing: 6) {
                Image(systemName: "hand.tap")
                Text("タップして定義を確認")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
            )
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .background(cardBackground)
    }

    // MARK: - 裏面

    private var cardBack: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                // 見出し語（小さく）+ 発声ボタン
                HStack {
                    Text(word.word)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    speakButton {
                        speechService.speak(word: word.word, audioURL: word.audioURL)
                    }
                }

                Divider()

                // 英文解説 + 発声ボタン
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Label("Definition", systemImage: "text.alignleft")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Spacer()
                        speakButton { speechService.speakText(word.definition) }
                    }
                    Text(word.definition)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // 例文 + 発声ボタン（あれば）
                if !word.example.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label("Example", systemImage: "quote.opening")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Spacer()
                            speakButton { speechService.speakText(word.example) }
                        }
                        Text(word.example)
                            .font(.body)
                            .italic()
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray5)))
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .background(cardBackground)
    }

    // MARK: - 共通発声ボタン

    private func speakButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.caption)
                .foregroundStyle(.blue)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.blue.opacity(0.12)))
        }
    }

    // MARK: - カード背景

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(.secondarySystemBackground))
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
    }
}
