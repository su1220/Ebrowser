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
| データ永続化 | SwiftData（CloudKit は Phase 6 で有効化予定） |
| 辞書API | Free Dictionary API（`dictionaryapi.dev`・無料・APIキー不要） |
| 音声再生 | AVFoundation（AVPlayer / AVSpeechSynthesizer） |
| プロジェクト生成 | xcodegen（`project.yml`） |

---

## 機能仕様

### 1. ブラウザ機能

#### 1-1. 基本ナビゲーション
- アドレスバー（URL入力・キーワード入力でGoogle検索）
- フォーカス時に × クリアボタンを表示
- 戻る・進む・リロードボタン
- 読み込み進捗バー（ProgressView・KVO で estimatedProgress 監視）

#### 1-2. ブックマーク
- ページのブックマーク登録・削除（アドレスバー横の星ボタン）
- ブックマーク一覧画面（スワイプ削除）
- タップで該当ページへ遷移（AppViewModel 経由でタブ切り替え）

#### 1-3. 閲覧履歴
- 自動記録（タイトル・URL・日時）
- 履歴一覧画面（スワイプ削除・全削除）
- タップで該当ページへ遷移

#### 1-4. タブバー
- `UITabBarAppearance` で完全不透明に固定（サイト背景色の透過を防止）

---

### 2. 単語解説機能

#### 2-1. トリガー
- WKWebView 上のテキストを**長押し**すると単語が選択される
- JavaScript インジェクション（`touchstart` 500ms タイマー）で単語を取得
- `WeakScriptMessageHandler` で循環参照を防止

#### 2-2. 解説表示（ボトムシート）
- `WordDefinitionSheet`（`NavigationStack` + `NavigationPath`）
- 表示内容：
  - 見出し語・品詞バッジ・発音ボタン（API音声URL → AVSpeechSynthesizer フォールバック）
  - 英文解説（Definition）+ 個別発声ボタン
  - 英文例文（Example）+ 個別発声ボタン
  - 「単語帳に追加」ボタン → フォルダ選択シート

#### 2-3. 解説シート内の単語長押し（Phase 3.5）
- Definition・Example を `LongPressTextView`（UITextView ラッパー）で表示
- 長押しで単語を検出 → `NavigationPath` にプッシュして入れ子検索が可能
- 同一単語の重複プッシュを `Set<String>` で防止

#### 2-4. APIレスポンス仕様
```
GET https://api.dictionaryapi.dev/api/v2/entries/en/{word}
```
- 使用フィールド：`word`, `meanings[].partOfSpeech`, `meanings[].definitions[].definition`, `meanings[].definitions[].example`, `phonetics[].audio`
- エラー時（404など）：「単語が見つかりません」メッセージ表示

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
    var folder: WordFolder?     // nil = Unfiled
    var sourceURL: String?      // 保存時のページURL
    var memo: String            // ユーザーメモ（URL貼り付け可）
}
```

#### 3-2. フォルダ管理
- フォルダの作成（名前入力アラート）・削除・リネーム（長押しコンテキストメニュー）
- フォルダ削除時は所属単語を Unfiled に移動して保持
- FolderPickerView（単語保存時）でもフォルダ作成可能

#### 3-3. 単語一覧
- フォルダごとの単語リスト表示（品詞バッジ・定義プレビュー）
- スワイプ削除・長押しでフォルダ間移動

#### 3-4. 単語詳細
- 英文解説・例文（Definition・Example）に個別発声ボタン
- Definition・Example を `LongPressTextView` で表示 → 長押しで単語検索シート表示
- クリップボードコピー（ハプティクスフィードバック付き）：
  ```
  [Word] {word} ({partOfSpeech})
  [Definition] {definition}
  [Example] {example}
  ```
- Source URL タップ → ブラウザタブへジャンプ
- メモ欄（TextEditor）：自由記述・SwiftData 自動保存
  - メモ内 URL を NSDataDetector で自動検出 → タップでブラウザを開く

#### 3-5. iCloud同期
- Phase 6 で CloudKit を有効化予定
- 現在は `ModelConfiguration(cloudKitDatabase: .none)` でローカル動作

---

### 4. フラッシュカード学習機能

#### 4-1. 学習開始
- 単語帳タブの「学習する」ボタン（左上ツールバー）またはフラッシュカードタブから開始
- フォルダ単位 or すべての単語を Picker で選択
- シャッフル ON/OFF トグル

#### 4-2. カード表示仕様
- **表面**: 見出し語 + 品詞バッジ + 発音ボタン + タップヒント（カプセルスタイル）
- **裏面**: 英文解説（発声ボタン付き）+ 例文（発声ボタン付き）
- SwiftUI の `rotation3DEffect` でカードめくりアニメーション
- **タップ**でカードをめくる
- **左スワイプ**（`DragGesture`）で次のカードへ進む

#### 4-3. 学習フロー
- 進捗バー（`n / 合計` 表示）
- 最後のカードで「学習完了」画面
- 「もう一度学習する」「設定に戻る」ボタン

---

## タブ間通信

`AppViewModel`（`@Observable`）を `ContentView` で `.environment()` 注入。
全タブ・全子ビューから `@Environment(AppViewModel.self)` で参照可能。

```swift
appViewModel.openInBrowser(url:)  // ブラウザタブへジャンプ
appViewModel.selectedTab = .flashcard  // タブ切り替え
```

---

## 画面構成

```
TabView（ContentView）
├── ブラウザタブ（BrowserView）
│   ├── AddressBarView（URLバー・×ボタン・ブックマーク）
│   ├── WKWebView（WebViewRepresentable）
│   └── WordDefinitionSheet（単語解説ボトムシート）
│       └── WordDefinitionContentView（LongPressTextView 搭載）
├── 単語帳タブ（FolderListView）
│   ├── WordListView（単語一覧）
│   └── WordDetailView（単語詳細・LongPressTextView・メモ欄）
├── フラッシュカードタブ（FlashcardSessionView）
│   ├── セットアップ画面
│   ├── FlashcardView（カードコンポーネント）
│   └── 完了画面
└── 設定タブ（SettingsView）
    ├── BookmarkView
    └── HistoryView
```

---

## プロジェクト構成

```
Ebrowser/
├── EbrowserApp.swift
├── ContentView.swift
├── Constants.swift                 # 定数・String Identifiable 拡張
├── Models/
│   ├── WordFolder.swift
│   ├── SavedWord.swift             # memo フィールドあり
│   ├── Bookmark.swift
│   └── BrowsingHistory.swift
├── Views/
│   ├── Browser/
│   │   ├── BrowserView.swift
│   │   ├── AddressBarView.swift    # × クリアボタンあり
│   │   ├── WebViewRepresentable.swift
│   │   ├── WordDefinitionSheet.swift   # NavigationPath 対応
│   │   ├── WordDefinitionContentView.swift
│   │   ├── LongPressTextView.swift     # UITextView ラッパー
│   │   └── FolderPickerView.swift
│   ├── WordBook/
│   │   ├── FolderListView.swift
│   │   ├── WordListView.swift
│   │   └── WordDetailView.swift    # メモ欄・LongPressTextView 搭載
│   ├── Flashcard/
│   │   ├── FlashcardSessionView.swift
│   │   └── FlashcardView.swift
│   └── Settings/
│       ├── SettingsView.swift
│       ├── BookmarkView.swift
│       └── HistoryView.swift
├── ViewModels/
│   ├── AppViewModel.swift          # タブ間共有状態
│   ├── BrowserViewModel.swift
│   ├── WordDefinitionViewModel.swift
│   ├── FlashcardViewModel.swift
│   └── WordBookViewModel.swift
└── Services/
    ├── DictionaryService.swift
    └── SpeechService.swift
```

---

## コーディング規約

- コメントは日本語で記述
- SwiftUI の `@Observable` マクロを使用（iOS 17+）
- `@Observable` クラスの環境注入は `.environment(obj)` + `@Environment(Type.self)`
- 非同期処理は `async/await` を使用
- エラーハンドリングは `do-catch` + ユーザーへのトースト/アラート表示
- ハードコーディング禁止、定数は `enum Constants` に集約
- SwiftData モデルの変更時はデフォルト値を付与して既存データを保護

---

## 注意事項・制約

- WKWebView の JS インジェクション：一部 CSP 制限サイトでは単語選択が動作しない場合あり
- Free Dictionary API：一般英語単語向け。専門用語・固有名詞は 404 になる場合あり
- `LongPressTextView`：`AutoSizingTextView` サブクラスで `layoutSubviews` 毎に高さ再計算（NavigationStack プッシュ後の表示崩れ対策）
- `WeakScriptMessageHandler`：`WKUserContentController` の循環参照を防ぐラッパー
- App Store 公開を前提とする場合、WKWebView の使用はガイドライン準拠
