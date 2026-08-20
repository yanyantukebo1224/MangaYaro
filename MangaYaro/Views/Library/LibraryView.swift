import SwiftUI

/// 動的進捗更新 & お気に入りフィルター対応のライブラリ画面
public struct LibraryView: View {
    @ObservedObject private var dataService = MockDataService.shared
    @State private var filterSegment: Int = 0 // 0: お気に入り, 1: 読書履歴・すべて
    
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
                        Text("ライブラリ")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        // フィルターセグメント
                        Picker("Filter", selection: $filterSegment) {
                            Text("お気に入り").tag(0)
                            Text("すべての作品").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)
                        
                        let displayMangas = filterSegment == 0
                            ? dataService.mangas.filter { $0.isFavorite }
                            : dataService.mangas
                        
                        if displayMangas.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "books.vertical")
                                    .font(.system(size: 44))
                                    .foregroundColor(.gray)
                                Text(filterSegment == 0 ? "お気に入りの作品はありません" : "ライブラリに作品がありません")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 50)
                        } else {
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(displayMangas) { manga in
                                    NavigationLink(destination: MangaDetailView(manga: manga)) {
                                        mangaPosterCard(manga)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
            }
        }
    }
    
    private func mangaPosterCard(_ manga: Manga) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                ColorExtractor.themeGradient(for: manga.title)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                
                VStack {
                    Image(systemName: manga.coverImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // お気に入りハート
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                
                // 読書進捗バー（下部オーバーレイ）
                VStack(alignment: .leading, spacing: 4) {
                    Text(manga.title)
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // プログレスバー
                    GeometryReader { p in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                            Capsule()
                                .fill(Color.accentColor)
                                .frame(width: max(4, p.size.width * CGFloat(manga.overallProgress)))
                        }
                    }
                    .frame(height: 4)
                }
                .padding(10)
                .background(
                    Rectangle()
                        .fill(Material.ultraThinMaterial)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            HStack {
                Text("\(Int(manga.overallProgress * 100))% 読了")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                if let lastPage = manga.lastReadPageIndex {
                    Text("P.\(lastPage)")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}
