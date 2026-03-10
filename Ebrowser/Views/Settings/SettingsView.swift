import SwiftUI

/// 設定タブ（ブックマーク・履歴）
struct SettingsView: View {

    var appViewModel: AppViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("ブラウザ") {
                    NavigationLink {
                        BookmarkView { url in
                            appViewModel.openInBrowser(url: url)
                        }
                    } label: {
                        Label("ブックマーク", systemImage: "bookmark.fill")
                    }

                    NavigationLink {
                        HistoryView { url in
                            appViewModel.openInBrowser(url: url)
                        }
                    } label: {
                        Label("閲覧履歴", systemImage: "clock.fill")
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    SettingsView(appViewModel: AppViewModel())
        .modelContainer(for: [Bookmark.self, BrowsingHistory.self], inMemory: true)
}
