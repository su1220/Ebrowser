import SwiftUI
import SwiftData

@main
struct EbrowserApp: App {

    // SwiftData の ModelContainer（CloudKit同期を将来有効化する準備済み）
    let modelContainer: ModelContainer = {
        let schema = Schema([
            WordFolder.self,
            SavedWord.self,
            Bookmark.self,
            BrowsingHistory.self,
        ])
        // Phase 6 で CloudKit を有効化する際は .private("iCloud.com.ebrowser.app") に変更
        let config = ModelConfiguration(cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("ModelContainer の初期化に失敗しました: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
