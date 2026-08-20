import Foundation
import Combine

/// アプリ全体のデータストレージ＆検索サービス (ObservableObject)
public class MockDataService: ObservableObject {
    public static let shared = MockDataService()
    
    @Published public var mangas: [Manga] = []
    
    private init() {
        self.mangas = generateSampleData()
    }
    
    /// 作品の検索＆フィルタリング
    public func searchMangas(query: String, genre: String = "すべて") -> [Manga] {
        return mangas.filter { manga in
            let matchesQuery = query.isEmpty ||
                manga.title.localizedCaseInsensitiveContains(query) ||
                manga.author.localizedCaseInsensitiveContains(query) ||
                manga.summary.localizedCaseInsensitiveContains(query) ||
                manga.tags.contains { $0.localizedCaseInsensitiveContains(query) }
            
            let matchesGenre = (genre == "すべて") || manga.tags.contains(genre)
            
            return matchesQuery && matchesGenre
        }
    }
    
    /// お気に入り状態の切り替え
    public func toggleFavorite(mangaId: String) {
        if let index = mangas.firstIndex(where: { $0.id == mangaId }) {
            mangas[index].isFavorite.toggle()
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
    
    /// チャプターダウンロード状態の更新
    public func updateDownloadState(mangaId: String, chapterId: String, state: Chapter.DownloadState) {
        guard let mangaIndex = mangas.firstIndex(where: { $0.id == mangaId }) else { return }
        if let chapterIndex = mangas[mangaIndex].chapters.firstIndex(where: { $0.id == chapterId }) {
            mangas[mangaIndex].chapters[chapterIndex].downloadState = state
        }
    }
    
    private func generateSampleData() -> [Manga] {
        // 作品1: サイバーフロンティア
        let manga1Pages = (1...12).map { idx in
            Page(
                pageIndex: idx,
                imageURL: SampleImageProvider.pageURL(seed: "cyber", pageIndex: idx),
                imageName: "sparkles"
            )
        }
        let manga1Chapters = [
            Chapter(chapterNumber: 1, title: "第1話: 電脳都市ネオTOKYO", pageCount: 12, isRead: true, downloadState: .downloaded, pages: manga1Pages),
            Chapter(chapterNumber: 2, title: "第2話: 漆黒のプロトコル", pageCount: 12, isRead: true, downloadState: .downloaded, pages: manga1Pages),
            Chapter(chapterNumber: 3, title: "第3話: 深層Webのダイバー", pageCount: 12, isRead: false, downloadState: .notDownloaded, pages: manga1Pages),
            Chapter(chapterNumber: 4, title: "第4話: 仮想のゴースト", pageCount: 12, isRead: false, downloadState: .notDownloaded, pages: manga1Pages),
        ]
        let manga1 = Manga(
            id: "manga-cyber",
            title: "Cyber Frontier",
            author: "ネオ・TOKYO",
            coverImageName: "sparkles",
            summary: "近未来のサイバーパンク都市を舞台に、電脳世界の深淵に挑むハッカー少女の戦いを描くスタイリッシュSFアクション！",
            tags: ["SF・ファンタジー", "バトル", "サイバーパンク"],
            chapters: manga1Chapters,
            lastReadChapterId: manga1Chapters[1].id,
            lastReadPageIndex: 5,
            isFavorite: true
        )
        
        // 作品2: 炎の錬金騎士団
        let manga2Pages = (1...15).map { idx in
            Page(
                pageIndex: idx,
                imageURL: SampleImageProvider.pageURL(seed: "flame", pageIndex: idx),
                imageName: "flame.fill"
            )
        }
        let manga2Chapters = [
            Chapter(chapterNumber: 1, title: "第1話: 始まりの焔", pageCount: 15, isRead: true, downloadState: .downloaded, pages: manga2Pages),
            Chapter(chapterNumber: 2, title: "第2話: 師匠の教え", pageCount: 15, isRead: false, downloadState: .notDownloaded, pages: manga2Pages),
            Chapter(chapterNumber: 3, title: "第3話: 限界突破の刃", pageCount: 15, isRead: false, downloadState: .notDownloaded, pages: manga2Pages),
        ]
        let manga2 = Manga(
            id: "manga-flame",
            title: "炎の錬金騎士団",
            author: "火ノ宮 炎太",
            coverImageName: "flame.fill",
            summary: "世界を焼き尽くす魔王を倒すため、ちっぽけな熱意と無敵の剣技で駆け抜ける熱血王道ファンタジー！",
            tags: ["SF・ファンタジー", "バトル", "王道"],
            chapters: manga2Chapters,
            lastReadChapterId: manga2Chapters[0].id,
            lastReadPageIndex: 1,
            isFavorite: true
        )
        
        // 作品3: コモレビ・デイズ
        let manga3Pages = (1...10).map { idx in
            Page(
                pageIndex: idx,
                imageURL: SampleImageProvider.pageURL(seed: "komorebi", pageIndex: idx),
                imageName: "leaf.fill"
            )
        }
        let manga3Chapters = [
            Chapter(chapterNumber: 1, title: "第1話: 雨上がりのカフェテラス", pageCount: 10, isRead: false, downloadState: .notDownloaded, pages: manga3Pages),
            Chapter(chapterNumber: 2, title: "第2話: 木漏れ日のスケッチ", pageCount: 10, isRead: false, downloadState: .notDownloaded, pages: manga3Pages),
        ]
        let manga3 = Manga(
            id: "manga-komorebi",
            title: "コモレビ・デイズ",
            author: "風間 すず",
            coverImageName: "leaf.fill",
            summary: "静かな田舎町の古民家カフェで繰り広げられる、心温まるスローライフ・日常縦スクロールストーリー。",
            tags: ["日常・スローライフ", "Webtoon", "癒やし"],
            chapters: manga3Chapters,
            lastReadChapterId: nil,
            lastReadPageIndex: nil,
            isFavorite: false
        )
        
        // 作品4: アビス・ウォーカー
        let manga4Pages = (1...14).map { idx in
            Page(
                pageIndex: idx,
                imageURL: SampleImageProvider.pageURL(seed: "abyss", pageIndex: idx),
                imageName: "eye.fill"
            )
        }
        let manga4Chapters = [
            Chapter(chapterNumber: 1, title: "第1話: 深淵からの手招き", pageCount: 14, isRead: false, downloadState: .notDownloaded, pages: manga4Pages),
            Chapter(chapterNumber: 2, title: "第2話: 迷宮の囁き", pageCount: 14, isRead: false, downloadState: .notDownloaded, pages: manga4Pages),
        ]
        let manga4 = Manga(
            id: "manga-abyss",
            title: "アビス・ウォーカー",
            author: "影山 零",
            coverImageName: "eye.fill",
            summary: "決して開けてはならない地下迷宮の扉が開く。生き残りをかけた極限サスペンス・ホラー！",
            tags: ["ホラー", "サスペンス", "Webtoon"],
            chapters: manga4Chapters,
            lastReadChapterId: nil,
            lastReadPageIndex: nil,
            isFavorite: false
        )
        
        return [manga1, manga2, manga3, manga4]
    }
}
