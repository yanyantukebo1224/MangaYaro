import Foundation
import Combine

/// アプリ全体のデータ管理およびMangaDex API統合マネージャー
public class MockDataService: ObservableObject {
    public static let shared = MockDataService()
    
    @Published public var mangas: [Manga] = []
    @Published public var searchResults: [Manga] = []
    @Published public var isLoading: Bool = false
    
    private var searchTask: Task<Void, Never>?
    
    private init() {
        Task {
            await fetchTrendingMangas()
        }
    }
    
    /// アプリ初期化時のトレンド作品フェッチ (MangaDex)
    @MainActor
    public func fetchTrendingMangas() async {
        isLoading = true
        do {
            let fetched = try await MangaDexService.shared.searchManga(query: "", limit: 20)
            if !fetched.isEmpty {
                self.mangas = fetched
                self.searchResults = fetched
            }
        } catch {
            print("MangaDex API fetch failed: \(error)")
        }
        isLoading = false
    }
    
    /// MangaDex APIでのリアルタイムライブ検索
    @MainActor
    public func searchMangas(query: String, genre: String = "すべて") {
        searchTask?.cancel()
        
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty || genre != "すべて" else {
            self.searchResults = self.mangas
            return
        }
        
        isLoading = true
        searchTask = Task {
            // 300msデバウンス
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            
            do {
                let fetched = try await MangaDexService.shared.searchManga(query: query, limit: 24)
                guard !Task.isCancelled else { return }
                
                let filtered = genre == "すべて" ? fetched : fetched.filter { $0.tags.contains(genre) }
                self.searchResults = filtered
            } catch {
                print("Search error: \(error)")
            }
            self.isLoading = false
        }
    }
    
    /// チャプター一覧のフェッチ (MangaDex)
    @MainActor
    public func fetchChapters(for mangaId: String) async -> [Chapter] {
        do {
            let chapters = try await MangaDexService.shared.fetchChapters(mangaId: mangaId)
            if let index = mangas.firstIndex(where: { $0.id == mangaId }) {
                mangas[index].chapters = chapters
            }
            return chapters
        } catch {
            print("Fetch chapters error: \(error)")
            return []
        }
    }
    
    /// チャプターの実全ページ画像URLをフェッチ (MangaDex @Home API)
    @MainActor
    public func fetchPages(for chapterId: String) async -> [Page] {
        do {
            return try await MangaDexService.shared.fetchChapterPages(chapterId: chapterId)
        } catch {
            print("Fetch pages error: \(error)")
            return []
        }
    }
    
    /// お気に入り状態の切り替え
    public func toggleFavorite(mangaId: String) {
        if let index = mangas.firstIndex(where: { $0.id == mangaId }) {
            mangas[index].isFavorite.toggle()
        } else if let searchIndex = searchResults.firstIndex(where: { $0.id == mangaId }) {
            var item = searchResults[searchIndex]
            item.isFavorite.toggle()
            searchResults[searchIndex] = item
            if !mangas.contains(where: { $0.id == mangaId }) {
                mangas.append(item)
            }
        }
    }
    
    /// 読書位置・既読進捗の保存
    public func updateReadingProgress(mangaId: String, chapterId: String, pageIndex: Int) {
        guard let mangaIndex = mangas.firstIndex(where: { $0.id == mangaId }) else { return }
        
        mangas[mangaIndex].lastReadChapterId = chapterId
        mangas[mangaIndex].lastReadPageIndex = pageIndex
        
        if let chapterIndex = mangas[mangaIndex].chapters.firstIndex(where: { $0.id == chapterId }) {
            mangas[mangaIndex].chapters[chapterIndex].isRead = true
        }
    }
}
