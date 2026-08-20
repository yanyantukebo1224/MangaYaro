import SwiftUI

/// MangaDex APIによるリアルタイムオンライン検索に対応した「見つける」画面
public struct DiscoverView: View {
    @ObservedObject private var dataService = MockDataService.shared
    
    @State private var searchText: String = ""
    @State private var selectedGenre: String = "すべて"
    
    private let genres = ["すべて", "SF・ファンタジー", "バトル", "日常・スローライフ", "Webtoon", "ホラー"]
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("見つける")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        // リアルタイム検索バー (MangaDex API)
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("MangaDexで作品名・作者を検索", text: $searchText)
                                .foregroundColor(.white)
                                .autocorrectionDisabled()
                                .onChange(of: searchText) { newValue in
                                    dataService.searchMangas(query: newValue, genre: selectedGenre)
                                }
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    dataService.searchMangas(query: "", genre: selectedGenre)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.08))
                        )
                        .padding(.horizontal, 20)
                        
                        // ジャンルチップ
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(genres, id: \.self) { genre in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedGenre = genre
                                            dataService.searchMangas(query: searchText, genre: genre)
                                        }
                                    }) {
                                        Text(genre)
                                            .font(.subheadline.weight(selectedGenre == genre ? .bold : .regular))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(selectedGenre == genre ? Color.accentColor : Color.white.opacity(0.1))
                                            )
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // 検索結果 / トレンドセクション
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text(searchText.isEmpty ? "🔥 MangaDex トレンド作品" : "検索結果 (\(dataService.searchResults.count)件)")
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(.white)
                                Spacer()
                                if dataService.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            if dataService.searchResults.isEmpty && !dataService.isLoading {
                                VStack(spacing: 12) {
                                    Image(systemName: "text.magnifyingglass")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("該当する作品がMangaDexで見つかりませんでした")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                            } else {
                                LazyVGrid(columns: columns, spacing: 20) {
                                    ForEach(dataService.searchResults) { manga in
                                        NavigationLink(destination: MangaDetailView(manga: manga)) {
                                            mangaCard(manga)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
            }
        }
    }
    
    private func mangaCard(_ manga: Manga) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let coverURL = manga.coverImageURL {
                        AsyncImage(url: coverURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            default:
                                ColorExtractor.themeGradient(for: manga.title)
                            }
                        }
                    } else {
                        ColorExtractor.themeGradient(for: manga.title)
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                
                // お気に入りハートボタン
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        dataService.toggleFavorite(mangaId: manga.id)
                    }
                }) {
                    Image(systemName: manga.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(manga.isFavorite ? .red : .white.opacity(0.8))
                        .padding(8)
                        .background(Circle().fill(Material.ultraThinMaterial))
                        .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(manga.title)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(manga.author)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
    }
}
