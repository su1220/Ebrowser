# Ebrowser - 英語学習特化型iOSブラウザ 仕様書

## プロジェクト概要

英語テック記事・ニュース記事の閲覧に特化したiOSブラウザ。
わからない単語を長押しすると英文で解説が表示され、単語を登録して後からフラッシュカードで学習できる。

---

## 技術スタック

| 項目 | 採用技術 |
|------|---------|
| 言語 | Swift 5.9+ |
| UI フレームワーク | SwiftUI |
| 最低対応iOS | iOS 17.0 |
| 開発環境 | Xcode 16.2 |
| ブラウザエンジン | WKWebView |
| データ永続化 | SwiftData + CloudKit（iCloud同期） |
| 辞書API | Free Dictionary API（`dictionaryapi.dev`） |
| 音声再生 | AVFoundation（AVSpeechSynthesizer / API音声URL） |

---

## 機能仕様

### 1. ブラウザ機能

#### 1-1. 基本ナビゲーション
- アドレスバー（URL入力・検索キーワード入力でGoogle検索）
- 戻る・進む・リロードボタン
- 読み込み進捗バー（ProgressView）

#### 1-2. ブックマーク
- ページのブックマーク登録・削除
- ブックマーク一覧画面（タイトル・URL表示）
- タップで該当ページへ遷移

#### 1-3. 閲覧履歴
- 自動記録（タイトル・URL・日時）
- 履歴一覧画面
- 履歴からの再訪問
- 履歴の全削除機能

---

### 2. 単語解説機能

#### 2-1. トリガー
- WKWebView上のテキストを**長押し**すると単語が選択される
- JavaScriptインジェクションで選択テキストを取得してネイティブ側へ送信

#### 2-2. 解説表示（ボトムシート）
- 画面下部からスライドアップするシート（`.sheet` or `UIPresentationController`）
- 表示内容：
  - 見出し語（単語）
  - 品詞
  - **英文による意味解説**（Free Dictionary APIの`definition`）
  - **英文例文**（Free Dictionary APIの`example`）
  - **発音ボタン**（APIの音声URL再生 → フォールバックでAVSpeechSynthesizer）
  - 「単語帳に追加」ボタン

#### 2-3. APIレスポンス仕様
```
GET https://api.dictionaryapi.dev/api/v2/entries/en/{word}
```
- 使用フィールド：`word`, `meanings[].partOfSpeech`, `meanings[].definitions[].definition`, `meanings[].definitions[].example`, `phonetics[].audio`
- エラー時（404など）：「この単語は見つかりませんでした」メッセージ表示

---

### 3. 単語帳機能

#### 3-1. データモデル（SwiftData）

```swift
@Model class WordFolder {
    var name: String
    var createdAt: Date
    var words: [SavedWord]
}

@Model class SavedWord {
    var word: String
    var partOfSpeech: String
    var definition: String      // 英文解説
    var example: String         // 例文
    var audioURL: String?       // 発音音声URL
    var savedAt: Date
    var folder: WordFolder?
    var sourceURL: String?      // 保存時のページURL
}
```

#### 3-2. フォルダ管理
- フォルダの作成・削除・リネーム
- デフォルトフォルダ「すべての単語」（フォルダ未分類の単語を表示）
- 単語をフォルダ間で移動

#### 3-3. 単語一覧
- フォルダごとの単語リスト表示
- 単語タップで詳細（解説・例文・発音）を表示

#### 3-4. クリップボードコピー
- 単語詳細画面またはボトムシートに「コピー」ボタン
- コピー内容（プレーンテキスト）：
  ```
  [Word] {word} ({partOfSpeech})
  [Definition] {definition}
  [Example] {example}
  ```

#### 3-5. iCloud同期
- SwiftData の `ModelContainer` に CloudKit を設定
- ネットワーク不在時はローカル動作、復帰時に自動同期

---

### 4. フラッシュカード学習機能

#### 4-1. 学習開始
- 単語帳画面から「学習する」ボタン
- フォルダ単位で学習対象を選択可能

#### 4-2. カード表示仕様
- **表面**: 見出し語 + 発音ボタン
- **裏面**: 英文解説 + 例文（タップまたはスワイプでめくる）
- SwiftUIの `rotation3DEffect` でカードめくりアニメーション

#### 4-3. 学習フロー
- カードを順に表示（ランダム順オプションあり）
- 「次へ」ボタンで次のカードへ
- 最後のカードで「学習完了」画面（何枚学習したか表示）

---

## 画面構成

```
TabView
├── ブラウザタブ
│   ├── アドレスバー
│   ├── WKWebView
│   └── ボトムシート（単語解説）
├── 単語帳タブ
│   ├── フォルダ一覧
│   └── 単語一覧・詳細
├── フラッシュカードタブ
│   └── カード学習画面
└── 設定タブ
    ├── ブックマーク管理
    └── 閲覧履歴
```

---

## プロジェクト構成

```
Ebrowser/
├── EbrowserApp.swift
├── ContentView.swift               # TabView ルート
├── Models/
│   ├── WordFolder.swift            # SwiftData モデル
│   ├── SavedWord.swift             # SwiftData モデル
│   ├── Bookmark.swift              # SwiftData モデル
│   └── BrowsingHistory.swift       # SwiftData モデル
├── Views/
│   ├── Browser/
│   │   ├── BrowserView.swift
│   │   ├── AddressBarView.swift
│   │   └── WordDefinitionSheet.swift
│   ├── WordBook/
│   │   ├── FolderListView.swift
│   │   ├── WordListView.swift
│   │   └── WordDetailView.swift
│   ├── Flashcard/
│   │   ├── FlashcardSessionView.swift
│   │   └── FlashcardView.swift
│   └── Settings/
│       ├── BookmarkView.swift
│       └── HistoryView.swift
├── ViewModels/
│   ├── BrowserViewModel.swift
│   ├── WordBookViewModel.swift
│   └── FlashcardViewModel.swift
└── Services/
    ├── DictionaryService.swift     # Free Dictionary API クライアント
    └── SpeechService.swift        # 音声再生
```

---

## コーディング規約

- コメントは日本語で記述
- SwiftUI の `@Observable` マクロを使用（iOS 17+）
- 非同期処理は `async/await` を使用
- エラーハンドリングは `do-catch` + ユーザーへのアラート表示
- ハードコーディング禁止、定数は `enum Constants` に集約

---

## 注意事項・制約

- WKWebView での JavaScript インジェクションによりテキスト選択を実装
- 一部サイト（CSP設定が厳しいサイト）ではJS注入が制限される場合あり
- Free Dictionary API は一般英語単語に特化。専門用語・固有名詞は404になる場合あり
- App Store 公開を前提とする場合、WKWebView の使用はガイドライン準拠
