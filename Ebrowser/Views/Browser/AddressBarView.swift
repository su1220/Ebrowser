import SwiftUI

/// ブラウザのアドレスバーとナビゲーションボタン
struct AddressBarView: View {

    @Binding var viewModel: BrowserViewModel
    var onBookmarkToggle: () -> Void

    @State private var isEditing = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // 戻るボタン
                Button {
                    viewModel.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 32, height: 32)
                }
                .disabled(!viewModel.canGoBack)

                // 進むボタン
                Button {
                    viewModel.goForward()
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 32, height: 32)
                }
                .disabled(!viewModel.canGoForward)

                // URLアドレス入力フィールド
                addressField

                // ブックマークボタン
                Button {
                    onBookmarkToggle()
                } label: {
                    Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                        .frame(width: 32, height: 32)
                        .foregroundStyle(viewModel.isBookmarked ? .yellow : .primary)
                }

                // リロード / 停止ボタン
                Button {
                    viewModel.reload()
                } label: {
                    Image(systemName: viewModel.isLoading ? "xmark" : "arrow.clockwise")
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // 読み込み進捗バー
            if viewModel.isLoading {
                ProgressView(value: viewModel.loadingProgress)
                    .progressViewStyle(.linear)
                    .tint(.blue)
                    .frame(height: 2)
            } else {
                Divider()
            }
        }
        .background(.bar)
    }

    // MARK: - アドレス入力フィールド

    private var addressField: some View {
        HStack(spacing: 4) {
            TextField("URLまたは検索キーワード", text: $viewModel.addressText)
                .textFieldStyle(.plain)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isFocused)
                .onSubmit {
                    viewModel.navigate(to: viewModel.addressText)
                    isFocused = false
                }

            // フォーカス中かつ入力があるときのみ×ボタンを表示
            if isFocused && !viewModel.addressText.isEmpty {
                Button {
                    viewModel.addressText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(.systemGray3))
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
        .onTapGesture {
            isFocused = true
        }
    }
}
