import SwiftUI
import SwiftData

/// ブラウザタブのメインビュー
struct BrowserView: View {

    var appViewModel: AppViewModel

    @State private var viewModel = BrowserViewModel()
    @State private var wordViewModel = WordDefinitionViewModel()

    @Query(sort: \Bookmark.savedAt, order: .reverse) private var bookmarks: [Bookmark]
    @Environment(\.modelContext) private var modelContext

    @State private var showBookmarkToast = false

    var body: some View {
        VStack(spacing: 0) {
            // アドレスバー
            AddressBarView(viewModel: $viewModel) {
                toggleBookmark()
            }

            // WebView 本体
            WebViewRepresentable(
                viewModel: $viewModel,
                onPageFinished: { title, url in
                    recordHistory(title: title, url: url)
                },
                onWordSelected: { word in
                    wordViewModel.lookup(word: word)
                }
            )
            .ignoresSafeArea(edges: .bottom)
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: bookmarks) {
            viewModel.checkIsBookmarked(bookmarks: bookmarks)
        }
        .onChange(of: viewModel.currentURL) {
            viewModel.checkIsBookmarked(bookmarks: bookmarks)
        }
        // ブックマーク・履歴からのジャンプ要求
        .onChange(of: appViewModel.pendingURL) { _, newURL in
            guard let url = newURL else { return }
            viewModel.navigate(to: url.absoluteString)
            appViewModel.pendingURL = nil
        }
        // ブックマーク追加完了トースト
        .overlay(alignment: .bottom) {
            if showBookmarkToast {
                bookmarkToastView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 20)
            }
        }
        .animation(.spring(duration: 0.3), value: showBookmarkToast)
        // 単語解説ボトムシート
        .sheet(isPresented: $wordViewModel.isShowingSheet) {
            WordDefinitionSheet(
                viewModel: wordViewModel,
                sourceURL: viewModel.currentURL?.absoluteString
            )
        }
    }

    // MARK: - ブックマーク操作

    private func toggleBookmark() {
        guard let url = viewModel.currentURL else { return }
        let urlString = url.absoluteString

        if let existing = bookmarks.first(where: { $0.url == urlString }) {
            modelContext.delete(existing)
            viewModel.isBookmarked = false
        } else {
            let bookmark = Bookmark(
                title: viewModel.pageTitle.isEmpty ? urlString : viewModel.pageTitle,
                url: urlString
            )
            modelContext.insert(bookmark)
            viewModel.isBookmarked = true
            showToast()
        }
    }

    private func recordHistory(title: String, url: String) {
        guard !url.isEmpty else { return }
        let history = BrowsingHistory(
            title: title.isEmpty ? url : title,
            url: url
        )
        modelContext.insert(history)
    }

    // MARK: - トースト

    private func showToast() {
        showBookmarkToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showBookmarkToast = false
        }
    }

    private var bookmarkToastView: some View {
        Label("ブックマークに追加しました", systemImage: "bookmark.fill")
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color(.systemGray2)))
    }
}

#Preview {
    BrowserView(appViewModel: AppViewModel())
        .modelContainer(for: [Bookmark.self, BrowsingHistory.self, WordFolder.self, SavedWord.self], inMemory: true)
}
