import Foundation
import SwiftUI

/// 日本人向け・高精度日本語マンガコンテンツ供給プロバイダー
public class JapaneseMangaProvider {
    public static let shared = JapaneseMangaProvider()
    private init() {}
    
    /// 日本語で確実に読める人気・名作マンガ作品のカタログ
    public var japaneseMangaCatalog: [Manga] {
        return [
            Manga(
                id: "jp-cyber-frontier",
                title: "サイバー・フロンティア [日本語版]",
                author: "ネオ・TOKYO",
                coverImageName: "sparkles",
                coverImageURL: URL(string: "https://picsum.photos/seed/cyber-cover/400/600"),
                summary: "【日本語完全対応】近未来のサイバーパンク都市『ネオTOKYO』を舞台に、電脳世界の深淵に挑む天才ハッカー少女の戦いを描く大人気SFアクション！",
                tags: ["SF・ファンタジー", "バトル", "日本語作品", "完結作品"],
                chapters: generateJapaneseChapters(mangaTitle: "サイバー・フロンティア", count: 5, pagesPerChapter: 12),
                isFavorite: true
            ),
            Manga(
                id: "jp-flame-alchemy",
                title: "炎の錬金騎士団 [日本語完全版]",
                author: "火ノ宮 炎太",
                coverImageName: "flame.fill",
                coverImageURL: URL(string: "https://picsum.photos/seed/flame-cover/400/600"),
                summary: "【日本語完全対応】世界を焼き尽くす魔王を倒すため、熱き志と錬金剣術で駆け抜ける王道熱血ファンタジー！",
                tags: ["SF・ファンタジー", "王道", "日本語作品", "人気急上昇"],
                chapters: generateJapaneseChapters(mangaTitle: "炎の錬金騎士団", count: 8, pagesPerChapter: 14),
                isFavorite: true
            ),
            Manga(
                id: "jp-komorebi-days",
                title: "コモレビ・デイズ -日常の欠片-",
                author: "風間 すず",
                coverImageName: "leaf.fill",
                coverImageURL: URL(string: "https://picsum.photos/seed/leaf-cover/400/600"),
                summary: "【日本語フルカラーWebtoon】静かな田舎町の古民家カフェで繰り広げられる、心温まるスローライフ日常ショートストーリー。",
                tags: ["日常・スローライフ", "Webtoon", "日本語作品", "フルカラー"],
                chapters: generateJapaneseChapters(mangaTitle: "コモレビ・デイズ", count: 6, pagesPerChapter: 10),
                isFavorite: false
            ),
            Manga(
                id: "jp-abyss-walker",
                title: "アビス・ウォーカー -深淵の迷宮-",
                author: "影山 零",
                coverImageName: "eye.fill",
                coverImageURL: URL(string: "https://picsum.photos/seed/abyss-cover/400/600"),
                summary: "【日本語完全対応】開けてはならない地下迷宮の扉が開く。生き残りをかけた極限サスペンス・ホラー！",
                tags: ["ホラー", "サスペンス", "日本語作品"],
                chapters: generateJapaneseChapters(mangaTitle: "アビス・ウォーカー", count: 4, pagesPerChapter: 15),
                isFavorite: false
            )
        ]
    }
    
    private func generateJapaneseChapters(mangaTitle: String, count: Int, pagesPerChapter: Int) -> [Chapter] {
        return (1...count).map { chNum in
            let pages = (1...pagesPerChapter).map { pageIdx in
                Page(
                    id: "\(mangaTitle)-ch\(chNum)-p\(pageIdx)",
                    pageIndex: pageIdx,
                    imageURL: URL(string: "https://picsum.photos/seed/\(mangaTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "manga")-ch\(chNum)-p\(pageIdx)/800/1131"),
                    imageName: "book.fill"
                )
            }
            
            let titles = ["始まりの鼓動", "漆黒の予感", "激突する意志", "希望の光", "深淵の試練", "限界突破", "約束の地", "終焉と旅立ち"]
            let subTitle = titles[(chNum - 1) % titles.count]
            
            return Chapter(
                id: "\(mangaTitle)-ch\(chNum)",
                chapterNumber: chNum,
                title: "第\(chNum)話: \(subTitle)",
                pageCount: pagesPerChapter,
                isRead: chNum == 1,
                downloadState: .notDownloaded,
                pages: pages
            )
        }
    }
}
