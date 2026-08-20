import Foundation
import Combine

/// アプリ全体のデータ管理・マルチソース検索統合マネージャー
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
    
    /// フォールバック用バックアップデータ
    public static let fallbackMangas: [Manga] = [
        Manga(
            id: "fb-1",
            title: "Cyber Frontier",
            author: "ネオ・TOKYO",
            coverImageName: "sparkles",
            coverImageURL: SampleImageProvider.coverURL(seed: "cyber"),
            summary: "近未来のサイバーパンク都市を舞台に、電脳世界の深淵に挑むハッカー少女の戦いを描くスタイリッシュSFアクション！",
            tags: ["SF・ファンタジー", "バトル", "サイバーパンク"],
            chapters: [
                Chapter(chapterNumber: 1, title: "[日本語] 第1話: 電脳都市", pageCount: 10, pages: (1...10).map { Page(pageIndex: $0, imageURL: SampleImageProvider.pageURL(seed: "cyber", pageIndex: $0)) }),
                Chapter(chapterNumber: 2, title: "[日本語] 第2話: 漆黒のプログラム", pageCount: 10, pages: (1...10).map { Page(pageIndex: $0, imageURL: SampleImageProvider.pageURL(seed: "cyber2", pageIndex: $0)) })
            ],
            isFavorite: true
        ),
        Manga(
            id: "fb-2",
            title: "炎の錬金騎士団",
            author: "火ノ宮 炎太",
            coverImageName: "flame.fill",
            coverImageURL: SampleImageProvider.coverURL(seed: "flame"),
            summary: "世界を焼き尽くす魔王を倒すため、ちっぽけな熱意と無敵の剣技で駆け抜ける熱血王道ファンタジー！",
            tags: ["SF・ファンタジー", "バトル"],
            chapters: [
                Chapter(chapterNumber: 1, title: "[日本語] 第1話: 始まりの焔", pageCount: 12, pages: (1...12).map { Page(pageIndex: $0, imageURL: SampleImageProvider.pageURL(seed: "flame", pageIndex: $0)) })
            ],
            isFavorite: true
        )
    ]
    
    /// トレンド作品のフェッチ (日本語優先・複数ソース総当たり)
    @MainActor
    public func fetchTrendingMangas() async {
        isLoading = true
        let fetched = await MangaSearchAggregator.shared.searchAllSources(query: "")
        if !fetched.isEmpty {
            self.mangas = fetched
            self.searchResults = fetched
        } else {
            self.mangas = MockDataService.fallbackMangas
            self.searchResults = MockDataService.fallbackMangas
        }
        isLoading = false
    }
    
    /// リアルタイムライブ検索 (総当たり＆重複排除マージ)
    @MainActor
    public func searchMangas(query: String, genre: String = "すべて") {
        searchTask?.cancel()
        
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty || genre != "すべて" else {
            self.searchResults = self.mangas
            return
        }
        
        isLoading = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            
            let fetched = await MangaSearchAggregator.shared.searchAllSources(query: query)
            guard !Task.isCancelled else { return }
            
            let filtered = genre == "すべて" ? fetched : fetched.filter { $0.tags.contains(genre) }
            self.searchResults = filtered.isEmpty ? MockDataService.fallbackMangas : filtered
            self.isLoading = false
        }
    }
    
    /// チャプター一覧の安全なフェッチ
    @MainActor
    public func fetchChapters(for mangaId: String) async -> [Chapter] {
        do {
            let chapters = try await MangaDexService.shared.fetchChapters(mangaId: mangaId)
            if !chapters.isEmpty {
                if let index = mangas.firstIndex(where: { $0.id == mangaId }) {
                    mangas[index].chapters = chapters
                }
                return chapters
            }
        } catch {
            print("Fetch chapters error: \(error)")
        }
        
        // フォールバックチャプターを返す
        return [
            Chapter(chapterNumber: 1, title: "[日本語] 第1話: はじまりの物語", pageCount: 8, pages: (1...8).map { Page(pageIndex: $0, imageURL: SampleImageProvider.pageURL(seed: mangaId, pageIndex: $0)) })
        ]
    }
    
    /// チャプターの全ページ画像URLをフェッチ (安全クランプ付き)
    @MainActor
    public func fetchPages(for chapterId: String) async -> [Page] {
        do {
            let pages = try await MangaDexService.shared.fetchChapterPages(chapterId: chapterId)
            if !pages.isEmpty {
                return pages
            }
        } catch {
            print("Fetch pages error: \(error)")
        }
        
        return (1...8).map { idx in
            Page(id: "\(chapterId)-\(idx)", pageIndex: idx, imageURL: SampleImageProvider.pageURL(seed: chapterId, pageIndex: idx))
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
