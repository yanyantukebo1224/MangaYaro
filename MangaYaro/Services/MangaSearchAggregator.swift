import Foundation

/// タイトルの正規化と重複排除を行うマージエンジン
public struct TitleDeduplicator {
    /// タイトル文字列を比較用に正規化（小文字化、スペース・記号除去）
    public static func normalize(_ title: String) -> String {
        let lowered = title.lowercased()
        let regex = try? NSRegularExpression(pattern: "[^a-z0-9\\u3040-\\u309f\\u30a0-\\u30ff\\u4e00-\\u9faf]", options: [])
        let range = NSRange(location: 0, length: lowered.utf16.count)
        return regex?.stringByReplacingMatches(in: lowered, options: [], range: range, withTemplate: "") ?? lowered
    }
    
    /// 複数ソースから取得したマンガリストを重複排除してマージする
    public static func mergeAndDeduplicate(_ list: [Manga]) -> [Manga] {
        var mergedMap: [String: Manga] = [:]
        var orderKeyList: [String] = []
        
        for manga in list {
            let key = normalize(manga.title)
            if key.isEmpty { continue }
            
            if var existing = mergedMap[key] {
                let combinedTags = Array(Set(existing.tags + manga.tags))
                let combinedChapters = mergeChapters(existing.chapters, manga.chapters)
                let bestCover = existing.coverImageURL ?? manga.coverImageURL
                let bestSummary = existing.summary.count >= manga.summary.count ? existing.summary : manga.summary
                
                existing = Manga(
                    id: existing.id,
                    title: existing.title,
                    author: existing.author.count >= manga.author.count ? existing.author : manga.author,
                    coverImageName: existing.coverImageName,
                    coverImageURL: bestCover,
                    summary: bestSummary,
                    tags: combinedTags,
                    chapters: combinedChapters,
                    lastReadChapterId: existing.lastReadChapterId ?? manga.lastReadChapterId,
                    lastReadPageIndex: existing.lastReadPageIndex ?? manga.lastReadPageIndex,
                    isFavorite: existing.isFavorite || manga.isFavorite
                )
                mergedMap[key] = existing
            } else {
                mergedMap[key] = manga
                orderKeyList.append(key)
            }
        }
        
        return orderKeyList.compactMap { mergedMap[$0] }
    }
    
    private static func mergeChapters(_ list1: [Chapter], _ list2: [Chapter]) -> [Chapter] {
        var map: [String: Chapter] = [:]
        for c in list1 + list2 {
            let key = "\(c.chapterNumber)-\(c.title)"
            if map[key] == nil || c.pages.count > (map[key]?.pages.count ?? 0) {
                map[key] = c
            }
        }
        return map.values.sorted(by: { $0.chapterNumber > $1.chapterNumber })
    }
}

/// 日本人向けマンガ検索アグリゲーター & マージエンジン
public class MangaSearchAggregator {
    public static let shared = MangaSearchAggregator()
    private init() {}
    
    /// 日本語マンガ最優先＆複数ソース総当たり検索
    public func searchAllSources(query: String) async -> [Manga] {
        var results: [Manga] = []
        
        // 1. 日本語ネイティブマンガカタログから優先抽出
        let japaneseMangas = JapaneseMangaProvider.shared.japaneseMangaCatalog
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            results.append(contentsOf: japaneseMangas)
        } else {
            let matchedJP = japaneseMangas.filter { m in
                m.title.localizedCaseInsensitiveContains(query) ||
                m.author.localizedCaseInsensitiveContains(query) ||
                m.summary.localizedCaseInsensitiveContains(query) ||
                m.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) })
            }
            results.append(contentsOf: matchedJP)
        }
        
        // 2. MangaDex APIからのオンライン検索（日本語対応作品優先）
        do {
            let mangaDexResults = try await MangaDexService.shared.searchManga(query: query, limit: 16)
            results.append(contentsOf: mangaDexResults)
        } catch {
            print("MangaDex search error: \(error)")
        }
        
        // 3. タイトル重複排除＆日本語化マージ
        return TitleDeduplicator.mergeAndDeduplicate(results)
    }
}
