# Ebrowser 作業計画

## フェーズ概要

```
Phase 1: プロジェクト基盤              （約1-2日）
Phase 2: ブラウザ基本機能              （約2-3日）
Phase 3: 単語解説機能                  （約2-3日）
Phase 4: 単語帳機能                    （約2-3日）
Phase 5: フラッシュカード機能          （約1-2日）
Phase 6: iCloud同期・仕上げ            （約1-2日）
```

---

## Phase 1: プロジェクト基盤

### 1-1. Xcodeプロジェクト作成
- [x] Xcode 16.2 で新規 iOS App プロジェクト作成（SwiftUI, Swift）
- [x] Bundle ID設定（`com.ebrowser.app`）
- [x] Deployment Target を iOS 17.0 に設定
- [x] Git リポジトリ初期化・`.gitignore` 設定

### 1-2. フォルダ構成・ファイル作成
- [x] `Models/`, `Views/`, `ViewModels/`, `Services/` フォルダ作成
- [x] SwiftData モデルファイル作成
  - [x] `WordFolder.swift`
  - [x] `SavedWord.swift`
  - [x] `Bookmark.swift`
  - [x] `BrowsingHistory.swift`
- [x] `EbrowserApp.swift` に `ModelContainer`（SwiftData）設定

### 1-3. 基盤設定
- [x] `ContentView.swift` に `TabView` 骨格実装（4タブ）
- [x] 各タブのプレースホルダービュー作成
- [x] `Constants.swift`（定数管理）作成

---

## Phase 2: ブラウザ基本機能

### 2-1. WKWebView ブラウザ実装
- [x] `BrowserView.swift` 作成
- [x] `WKWebView` を `UIViewRepresentable` でラップ（`WebViewRepresentable.swift`）
- [x] ページ読み込み・リロード実装
- [x] `BrowserViewModel.swift` 作成（URL管理・ナビゲーション状態）

### 2-2. アドレスバー
- [x] `AddressBarView.swift` 作成
- [x] URL入力・Returnキーでページ遷移
- [x] キーワード入力でGoogle検索（`https://www.google.com/search?q=`）
- [x] 戻る・進む・リロードボタン実装
- [x] 読み込み進捗バー（`ProgressView`）実装

### 2-3. ブックマーク機能
- [x] 現在ページをブックマーク登録するボタン（アドレスバー横）
- [x] `BookmarkView.swift` 作成（一覧・削除）
- [x] ブックマークタップで該当ページへ遷移

### 2-4. 閲覧履歴機能
- [x] ページ遷移時に自動記録（SwiftData）
- [x] `HistoryView.swift` 作成（一覧・全削除）
- [x] 履歴タップで該当ページへ遷移

---

## Phase 3: 単語解説機能

### 3-1. 長押し検出・単語取得
- [x] WKWebView に JavaScript インジェクション実装
  - 長押しイベント検出 JS 作成（touchstart 500ms タイマー）
  - 選択テキストを `window.webkit.messageHandlers` 経由でSwiftへ送信
- [x] `WKScriptMessageHandler` でメッセージ受信処理実装（WeakScriptMessageHandler で循環参照防止）

### 3-2. Dictionary API クライアント
- [x] `DictionaryService.swift` 作成
- [x] `async/await` で Free Dictionary API 呼び出し実装
- [x] レスポンスの Codable モデル定義
  - `word`, `partOfSpeech`, `definition`, `example`, `audioURL`
- [x] エラーハンドリング（404・ネットワークエラー）

### 3-3. 解説ボトムシート UI
- [x] `WordDefinitionSheet.swift` 作成
- [x] 見出し語・品詞・英文解説・例文を表示
- [x] 発音ボタン実装

### 3-4. 音声再生
- [x] `SpeechService.swift` 作成
- [x] API の音声 URL を `AVPlayer` で再生
- [x] URL が空の場合 `AVSpeechSynthesizer` でフォールバック再生

### 3-5. 「単語帳に追加」フロー
- [x] ボトムシートから追加ボタン
- [x] フォルダ選択シート表示（`FolderPickerView.swift`）
- [x] SwiftData に `SavedWord` 保存
- [x] 保存完了トースト表示

---

## Phase 3.5: 解説シート内の単語長押し

### 3.5-1. LongPressTextView 作成
- [x] `UITextView` を `UIViewRepresentable` でラップした `LongPressTextView.swift` 作成
- [x] `UILongPressGestureRecognizer` で長押し検出
- [x] `closestPosition(to:)` + 文字列解析で長押し位置の単語を取得
- [x] 英字のみの単語に絞るバリデーション
- [x] `isScrollEnabled = false` で親 ScrollView へスクロール委譲
- [x] `AutoSizingTextView` サブクラスで `intrinsicContentSize` を自動計算

### 3.5-2. WordDefinitionContentView 作成
- [x] 定義表示を再利用可能な `WordDefinitionContentView.swift` に切り出し
- [x] `NavigationStack` 内でのプッシュナビゲーション対応
- [x] 同じ単語の重複プッシュを防止

### 3.5-3. WordDefinitionSheet 更新
- [x] `NavigationPath` を導入してネスト遷移を管理
- [x] Definition・Example の `Text` を `LongPressTextView` に差し替え
- [x] `navigationDestination` で `WordDefinitionContentView` へ遷移

---

## Phase 4: 単語帳機能

### 4-1. フォルダ管理
- [ ] `FolderListView.swift` 作成
- [ ] フォルダ一覧表示
- [x] フォルダ作成（名前入力アラート）← FolderPickerView に先行実装済み
- [ ] フォルダ削除（スワイプ）
- [ ] フォルダリネーム（長押しコンテキストメニュー）

### 4-2. 単語一覧
- [ ] `WordListView.swift` 作成
- [ ] フォルダ内の単語一覧表示（単語・品詞）
- [ ] 単語削除（スワイプ）
- [ ] 単語をフォルダ間移動（長押しコンテキストメニュー）

### 4-3. 単語詳細
- [ ] `WordDetailView.swift` 作成
- [ ] 英文解説・例文・発音ボタン表示
- [ ] クリップボードコピーボタン実装
  ```
  [Word] {word} ({partOfSpeech})
  [Definition] {definition}
  [Example] {example}
  ```
- [ ] コピー完了フィードバック（ハプティクス）

---

## Phase 5: フラッシュカード機能

### 5-1. 学習セッション開始
- [ ] 単語帳画面に「学習する」ボタン追加
- [ ] 対象フォルダ選択UI
- [ ] ランダム順/登録順オプション

### 5-2. フラッシュカード UI
- [ ] `FlashcardView.swift` 作成
  - 表面: 見出し語 + 発音ボタン
  - 裏面: 英文解説 + 例文
  - `rotation3DEffect` によるカードめくりアニメーション
- [ ] タップでカードめくり
- [ ] 「次へ」ボタンで次のカードへ
- [ ] `FlashcardSessionView.swift` 作成（進捗バー・完了画面）

### 5-3. 学習完了画面
- [ ] 学習枚数の表示
- [ ] 「もう一度」「単語帳に戻る」ボタン

---

## Phase 6: iCloud同期・仕上げ

### 6-1. iCloud同期設定
- [ ] Xcode で CloudKit ケーパビリティ追加
- [ ] iCloud コンテナ設定
- [ ] `ModelContainer` を CloudKit バックエンドで設定
- [ ] 同期動作テスト（2台のシミュレータ or 実機）

### 6-2. UI仕上げ
- [ ] アプリアイコン設定
- [ ] ライトモード・ダークモード対応確認
- [ ] iPad 対応（基本レイアウト確認）
- [ ] 空状態（単語帳が空など）のUIプレースホルダー実装

### 6-3. エラーハンドリング整備
- [ ] ネットワーク未接続時のアラート
- [ ] API 404 時の「単語が見つかりません」表示
- [ ] iCloud 未ログイン時のフォールバック（ローカル保存のみ）

### 6-4. テスト・品質確認
- [ ] 主要ユーザーフローの手動動作確認
- [ ] 実機（iPhone）での動作確認
- [ ] メモリリーク確認（Instruments）

---

## 依存関係・注意事項

- **Free Dictionary API**: APIキー不要・完全無料（https://dictionaryapi.dev）
- **WKWebView JS注入**: CSP制限サイトでは単語選択が機能しない場合あり（許容範囲として扱う）
- **CloudKit**: Apple Developer Program（有料）が必要。ローカルのみで始める場合は Phase 6-1 をスキップ可

---

## 実装優先度

```
Must（必須）
  ├── ブラウザ基本（Phase 2）
  ├── 単語解説（Phase 3）
  └── 単語帳（Phase 4）

Should（あると良い）
  ├── フラッシュカード（Phase 5）
  └── iCloud同期（Phase 6-1）

Nice to have
  └── UI仕上げ（Phase 6-2〜）
```
