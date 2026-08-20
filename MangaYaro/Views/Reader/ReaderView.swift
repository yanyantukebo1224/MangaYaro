import SwiftUI

/// 読書モードの種類
public enum ReadingMode: String, CaseIterable, Identifiable {
    case paging = "Paging (横)"
    case webtoon = "Webtoon (縦)"
    public var id: String { rawValue }
}

/// 実読書位置同期＆スマートキャッシュ対応のフルスクリーンマンガリーダー
public struct ReaderView: View {
    public let manga: Manga
    public let chapter: Chapter
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPageIndex: Int = 1
    @State private var readingMode: ReadingMode = .paging
    @State private var showControls: Bool = true
    
    public init(manga: Manga, chapter: Chapter, initialPageIndex: Int = 1) {
        self.manga = manga
        self.chapter = chapter
        self._currentPageIndex = State(initialValue: initialPageIndex)
    }
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // メイン読書コンテンツ
            Group {
                switch readingMode {
                case .paging:
                    TabView(selection: $currentPageIndex) {
                        ForEach(chapter.pages) { page in
                            PageView(page: page, chapterTitle: chapter.title)
                                .tag(page.pageIndex)
                        }
                    }
                    #if os(iOS)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    #endif
                case .webtoon:
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 4) {
                                ForEach(chapter.pages) { page in
                                    PageView(page: page, chapterTitle: chapter.title)
                                        .id(page.pageIndex)
                                }
                            }
                        }
                    }
                }
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    showControls.toggle()
                }
            }
            
            // オーバーレイ UI: Liquid Glass コントロールバー
            if showControls {
                VStack {
                    topControlBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                    
                    bottomControlBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .ignoresSafeArea(.all, edges: .horizontal)
            }
        }
        .statusBar(hidden: !showControls)
        .onChange(of: currentPageIndex) { newIndex in
            // 実データの進捗保存
            MockDataService.shared.updateReadingProgress(mangaId: manga.id, chapterId: chapter.id, pageIndex: newIndex)
            
            // スマート先読みアクターへの通知
            Task {
                await PageCacheManager.shared.updatePrefetchWindow(chapter: chapter, currentPageIndex: newIndex - 1)
            }
        }
        .onAppear {
            MockDataService.shared.updateReadingProgress(mangaId: manga.id, chapterId: chapter.id, pageIndex: currentPageIndex)
            Task {
                await PageCacheManager.shared.updatePrefetchWindow(chapter: chapter, currentPageIndex: currentPageIndex - 1)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var topControlBar: some View {
        HStack(spacing: 16) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.backward.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(manga.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(chapter.title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 読書モード切替ボタン
            Picker("Mode", selection: $readingMode) {
                ForEach(ReadingMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Material.ultraThinMaterial)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.white.opacity(0.15)),
            alignment: .bottom
        )
    }
    
    private var bottomControlBar: some View {
        VStack(spacing: 14) {
            ReaderQuickSlider(
                currentPageIndex: $currentPageIndex,
                totalPages: chapter.pageCount,
                onPageSelected: { newPage in }
            )
            
            HStack {
                Button(action: {
                    if currentPageIndex > 1 { currentPageIndex -= 1 }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundColor(currentPageIndex > 1 ? .white : .gray.opacity(0.4))
                }
                .disabled(currentPageIndex <= 1)
                
                Spacer()
                
                Text("スマートキャッシュ: アクティブ (3 Pages Window)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Button(action: {
                    if currentPageIndex < chapter.pageCount { currentPageIndex += 1 }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundColor(currentPageIndex < chapter.pageCount ? .white : .gray.opacity(0.4))
                }
                .disabled(currentPageIndex >= chapter.pageCount)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 14)
        .background(Material.ultraThinMaterial)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.white.opacity(0.15)),
            alignment: .top
        )
    }
}
