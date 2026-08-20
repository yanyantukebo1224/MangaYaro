import Foundation

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
