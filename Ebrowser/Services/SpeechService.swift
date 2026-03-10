import Foundation
import AVFoundation

/// 音声再生サービス（Phase 3 で本実装）
final class SpeechService {

    private var audioPlayer: AVPlayer?
    private let synthesizer = AVSpeechSynthesizer()

    /// 音声URLがあればストリーミング再生、なければAVSpeechSynthesizerで読み上げ
    func speak(word: String, audioURL: String?) {
        if let urlString = audioURL,
           !urlString.isEmpty,
           let url = URL(string: urlString) {
            playAudioFromURL(url)
        } else {
            speakWithSynthesizer(text: word)
        }
    }

    /// URLから音声ファイルを再生する
    private func playAudioFromURL(_ url: URL) {
        audioPlayer = AVPlayer(url: url)
        audioPlayer?.play()
    }

    /// AVSpeechSynthesizer で英語音声を合成して再生する
    private func speakWithSynthesizer(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        synthesizer.speak(utterance)
    }

    /// 再生を停止する
    func stop() {
        audioPlayer?.pause()
        audioPlayer = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
