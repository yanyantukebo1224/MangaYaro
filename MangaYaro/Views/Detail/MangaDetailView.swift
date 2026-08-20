import SwiftUI

/// 日本人向け・日本語チャプター最優先の作品詳細画面
public struct MangaDetailView: View {
    @State public var manga: Manga
    @Environment(\.dismiss) private var dismiss
    
    @State private var chapters: [Chapter] = []
    @State private var isLoadingChapters: Bool = false
    @State private var selectedChapterForReading: Chapter? = nil
    @State private var isLoadingPages: Bool = false
    
    public init(manga: Manga) {
        self._manga = State(initialValue: manga)
    }
    
    public var body: some View {
        ZStack {
            ColorExtractor.themeGradient(for: manga.title)
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    headerCoverSection
                    
                    if isLoadingPages {
                        HStack(spacing: 8) {
                            ProgressView().tint(.white)
                            Text("日本語ページデータを準備中...")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Material.ultraThinMaterial))
                    }
                    
                    let displayChapters = chapters.isEmpty ? manga.chapters : chapters
                    
                    if let firstChapter = displayChapters.first {
                        primaryActionButton(chapter: firstChapter)
                    }
                    
                    summarySection
                    
                    chapterListSection(displayChapters: displayChapters)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadChapters()
        }
        .fullScreenCover(item: $selectedChapterForReading) { chapter in
            ReaderView(manga: manga, chapter: chapter, initialPageIndex: manga.lastReadPageIndex ?? 1)
        }
    }
    
    private func loadChapters() async {
        if !manga.chapters.isEmpty {
            self.chapters = manga.chapters
            return
        }
        
        isLoadingChapters = true
        let fetched = await MockDataService.shared.fetchChapters(for: manga.id)
        self.chapters = fetched
        self.manga.chapters = fetched
        isLoadingChapters = false
    }
    
    private func openChapterForReading(_ chapter: Chapter) {
        if !chapter.pages.isEmpty {
            selectedChapterForReading = chapter
            return
        }
        
        Task {
            isLoadingPages = true
            let pages = await MockDataService.shared.fetchPages(for: chapter.id)
            let fullChapter = Chapter(
                id: chapter.id,
                chapterNumber: chapter.chapterNumber,
                title: chapter.title,
                pageCount: pages.count,
                isRead: chapter.isRead,
                downloadState: chapter.downloadState,
                pages: pages
            )
            isLoadingPages = false
            selectedChapterForReading = fullChapter
        }
    }
    
    // MARK: - Subviews
    
    private var headerCoverSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Group {
                    if let coverURL = manga.coverImageURL {
                        AsyncImage(url: coverURL) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                            default:
                                Color.gray.opacity(0.3)
                            }
                        }
                    } else {
                        Color.white.opacity(0.1)
                    }
                }
                .frame(width: 160, height: 230)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.6), radius: 16, x: 0, y: 8)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
            }
            
            VStack(spacing: 6) {
                Text(manga.title)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(manga.author)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private func primaryActionButton(chapter: Chapter) -> some View {
        Button(action: {
            openChapterForReading(chapter)
        }) {
            HStack {
                Image(systemName: "play.fill")
                Text("日本語で読む (\(chapter.title))")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Capsule().fill(Color.white))
            .foregroundColor(.black)
            .shadow(color: .white.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(manga.summary)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(manga.tags, id: \.self) { tag in
                        Text("# \(tag)")
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
        )
    }
    
    private func chapterListSection(displayChapters: [Chapter]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("日本語エピソード一覧 (\(displayChapters.count))")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                if isLoadingChapters {
                    ProgressView().tint(.white)
                }
            }
            
            VStack(spacing: 8) {
                ForEach(displayChapters) { chapter in
                    Button(action: {
                        openChapterForReading(chapter)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(chapter.title)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(chapter.isRead ? .white.opacity(0.6) : .white)
                                
                                Text("\(chapter.pageCount) ページ (日本語対応)")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            Spacer()
                            Image(systemName: "play.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.06))
                        )
                    }
                }
            }
        }
    }
}
