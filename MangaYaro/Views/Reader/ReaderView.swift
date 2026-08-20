import SwiftUI

/// 読書モードの種類
public enum ReadingMode: String, CaseIterable, Identifiable {
    case paging = "Paging (横)"
    case webtoon = "Webtoon (縦)"
    public var id: String { rawValue }
}

/// 100% クラッシュ保護＆安全フォールバック対応のフルスクリーンマンガリーダー
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
        let safeInitial = min(max(1, initialPageIndex), max(1, chapter.pages.count))
        self._currentPageIndex = State(initialValue: safeInitial)
    }
    
    /// 安全にインデックス範囲内のページを取得
    private var safePages: [Page] {
        if chapter.pages.isEmpty {
            return (1...6).map { idx in
                Page(id: "safe-\(idx)", pageIndex: idx, imageURL: SampleImageProvider.pageURL(seed: chapter.id, pageIndex: idx))
            }
        }
        return chapter.pages
    }
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            let pages = safePages
            let safePageIndex = min(max(1, currentPageIndex), pages.count)
            
            // メイン読書コンテンツ (安全ガード付き)
            Group {
                switch readingMode {
                case .paging:
                    TabView(selection: Binding(
                        get: { safePageIndex },
                        set: { currentPageIndex = $0 }
                    )) {
                        ForEach(pages) { page in
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
                                ForEach(pages) { page in
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
                    
                    bottomControlBar(totalPages: pages.count)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .ignoresSafeArea(.all, edges: .horizontal)
            }
        }
        .statusBar(hidden: !showControls)
        .onChange(of: currentPageIndex) { newIndex in
            MockDataService.shared.updateReadingProgress(mangaId: manga.id, chapterId: chapter.id, pageIndex: newIndex)
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
            
            // 読書モード切替
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
    
    private func bottomControlBar(totalPages: Int) -> some View {
        VStack(spacing: 14) {
            ReaderQuickSlider(
                currentPageIndex: $currentPageIndex,
                totalPages: totalPages,
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
                    if currentPageIndex < totalPages { currentPageIndex += 1 }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundColor(currentPageIndex < totalPages ? .white : .gray.opacity(0.4))
                }
                .disabled(currentPageIndex >= totalPages)
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
