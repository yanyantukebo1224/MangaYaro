import Foundation
import Combine

/// MangaDex REST API (`https://api.mangadex.org`) 日本語優先＆安全フォールバック対応サービス
public class MangaDexService {
    public static let shared = MangaDexService()
    private let baseURL = "https://api.mangadex.org"
    private let uploadsURL = "https://uploads.mangadex.org"
    
    private init() {}
    
    // MARK: - API Data Models
    
    public struct MangaDexListResponse<T: Decodable>: Decodable {
        public let result: String
        public let data: [T]
        public let total: Int?
    }
    
    public struct MangaData: Decodable {
        public let id: String
        public let attributes: MangaAttributes
        public let relationships: [Relationship]
    }
    
    public struct MangaAttributes: Decodable {
        public let title: [String: String]
        public let description: [String: String]
        public let tags: [Tag]?
        public let originalLanguage: String?
        
        public var mainTitle: String {
            title["ja"] ?? title["ja-ro"] ?? title["en"] ?? title.values.first ?? "無題"
        }
        
        public var mainDescription: String {
            description["ja"] ?? description["en"] ?? description.values.first ?? "説明なし"
        }
    }
    
    public struct Tag: Decodable {
        public let id: String
        public let attributes: TagAttributes
    }
    
    public struct TagAttributes: Decodable {
        public let name: [String: String]
        public var tagName: String {
            name["ja"] ?? name["en"] ?? name.values.first ?? ""
        }
    }
    
    public struct Relationship: Decodable {
        public let id: String
        public let type: String
        public let attributes: RelationshipAttributes?
    }
    
    public struct RelationshipAttributes: Decodable {
        public let fileName: String?
        public let name: String?
    }
    
    public struct ChapterData: Decodable {
        public let id: String
        public let attributes: ChapterAttributes
    }
    
    public struct ChapterAttributes: Decodable {
        public let volume: String?
        public let chapter: String?
        public let title: String?
        public let pages: Int
        public let translatedLanguage: String?
        
        public var displayTitle: String {
            let langTag = (translatedLanguage == "ja") ? "[日本語]" : "[EN]"
            let chStr = chapter != nil ? "第\(chapter!)話" : "チャプター"
            if let t = title, !t.isEmpty {
                return "\(langTag) \(chStr): \(t)"
            }
            return "\(langTag) \(chStr)"
        }
    }
    
    public struct AtHomeResponse: Decodable {
        public let baseUrl: String
        public let chapter: AtHomeChapter
    }
    
    public struct AtHomeChapter: Decodable {
        public let hash: String
        public let data: [String]
        public let dataSaver: [String]
    }
    
    // MARK: - API Methods
    
    /// 日本語作品を優先したMangaDex検索
    public func searchManga(query: String = "", limit: Int = 20) async throws -> [Manga] {
        var urlComponents = URLComponents(string: "\(baseURL)/manga")!
        var queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "includes[]", value: "cover_art"),
            URLQueryItem(name: "includes[]", value: "author"),
            URLQueryItem(name: "contentRating[]", value: "safe"),
            URLQueryItem(name: "contentRating[]", value: "suggestive"),
            URLQueryItem(name: "availableTranslatedLanguage[]", value: "ja"),
            URLQueryItem(name: "order[followedCount]", value: "desc")
        ]
        
        if !query.trimmingCharacters(in: .whitespaces).isEmpty {
            queryItems.append(URLQueryItem(name: "title", value: query))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else { return [] }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(MangaDexListResponse<MangaData>.self, from: data)
        
        return result.data.map { mData in
            let coverFileName = mData.relationships.first(where: { $0.type == "cover_art" })?.attributes?.fileName
            let coverURL: URL? = coverFileName != nil ? URL(string: "\(uploadsURL)/covers/\(mData.id)/\(coverFileName!)") : nil
            let tags = mData.attributes.tags?.compactMap { $0.attributes.tagName }.filter { !$0.isEmpty } ?? []
            let authorName = mData.relationships.first(where: { $0.type == "author" || $0.type == "artist" })?.attributes?.name ?? "MangaDex Creator"
            
            return Manga(
                id: mData.id,
                title: mData.attributes.mainTitle,
                author: authorName,
                coverImageName: "book.fill",
                coverImageURL: coverURL,
                summary: mData.attributes.mainDescription,
                tags: tags,
                chapters: [],
                lastReadChapterId: nil,
                lastReadPageIndex: nil,
                isFavorite: false
            )
        }
    }
    
    /// 日本語優先・英語フォールバックでチャプター一覧を取得
    public func fetchChapters(mangaId: String) async throws -> [Chapter] {
        var urlComponents = URLComponents(string: "\(baseURL)/manga/\(mangaId)/feed")!
        urlComponents.queryItems = [
            URLQueryItem(name: "limit", value: "96"),
            URLQueryItem(name: "translatedLanguage[]", value: "ja"),
            URLQueryItem(name: "translatedLanguage[]", value: "en"),
            URLQueryItem(name: "order[chapter]", value: "desc"),
            URLQueryItem(name: "contentRating[]", value: "safe"),
            URLQueryItem(name: "contentRating[]", value: "suggestive")
        ]
        
        guard let url = urlComponents.url else { return [] }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(MangaDexListResponse<ChapterData>.self, from: data)
        
        let chapters = result.data.compactMap { cData -> Chapter? in
            let chNum = Int(Double(cData.attributes.chapter ?? "1") ?? 1.0)
            return Chapter(
                id: cData.id,
                chapterNumber: chNum,
                title: cData.attributes.displayTitle,
                pageCount: max(1, cData.attributes.pages),
                isRead: false,
                downloadState: .notDownloaded,
                pages: []
            )
        }
        
        return chapters
    }
    
    /// チャプターの全ページ画像URLを取得 (@Home API) ＋ 安全保護
    public func fetchChapterPages(chapterId: String) async throws -> [Page] {
        guard let url = URL(string: "\(baseURL)/at-home/server/\(chapterId)") else {
            return generateFallbackPages(count: 8, chapterId: chapterId)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                return generateFallbackPages(count: 8, chapterId: chapterId)
            }
            
            let decoder = JSONDecoder()
            let result = try decoder.decode(AtHomeResponse.self, from: data)
            
            let baseUrl = result.baseUrl
            let hash = result.chapter.hash
            let filenames = result.chapter.data
            
            if filenames.isEmpty {
                return generateFallbackPages(count: 8, chapterId: chapterId)
            }
            
            return filenames.enumerated().compactMap { index, filename in
                let imageURL = URL(string: "\(baseUrl)/data/\(hash)/\(filename)")
                return Page(
                    id: "\(chapterId)-\(index + 1)",
                    pageIndex: index + 1,
                    imageURL: imageURL,
                    imageName: "doc.text.fill"
                )
            }
        } catch {
            return generateFallbackPages(count: 8, chapterId: chapterId)
        }
    }
    
    /// 万が一画像リンクの取得に失敗した場合の安全なプレースホルダーページ生成
    private func generateFallbackPages(count: Int, chapterId: String) -> [Page] {
        return (1...count).map { idx in
            Page(
                id: "\(chapterId)-fallback-\(idx)",
                pageIndex: idx,
                imageURL: SampleImageProvider.pageURL(seed: chapterId, pageIndex: idx),
                imageName: "book.fill"
            )
        }
    }
}
