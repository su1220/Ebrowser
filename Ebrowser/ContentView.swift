import SwiftUI

/// アプリのルートビュー（タブ構成）
struct ContentView: View {

    @State private var appViewModel = AppViewModel()

    init() {
        // タブバーを完全不透明に固定（サイト背景色の透過を防ぐ）
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: Binding(
            get: { appViewModel.selectedTab.rawValue },
            set: { appViewModel.selectedTab = AppTab(rawValue: $0) ?? .browser }
        )) {
            // ブラウザタブ
            BrowserView(appViewModel: appViewModel)
                .tabItem {
                    Label("ブラウザ", systemImage: "globe")
                }
                .tag(AppTab.browser.rawValue)

            // 単語帳タブ
            FolderListView()
                .tabItem {
                    Label("単語帳", systemImage: "book.fill")
                }
                .tag(AppTab.wordBook.rawValue)

            // フラッシュカードタブ
            FlashcardSessionView()
                .tabItem {
                    Label("学習", systemImage: "rectangle.on.rectangle")
                }
                .tag(AppTab.flashcard.rawValue)

            // 設定タブ（ブックマーク・履歴）
            SettingsView(appViewModel: appViewModel)
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
                .tag(AppTab.settings.rawValue)
        }
    }
}

#Preview {
    ContentView()
}
