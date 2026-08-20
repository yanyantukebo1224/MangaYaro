import SwiftUI

/// 実際の画像ダウンロード＆キャッシュ表示に対応した単一ページコンポーネント
public struct PageView: View {
    public let page: Page
    public let chapterTitle: String
    
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading: Bool = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    public init(page: Page, chapterTitle: String = "") {
        self.page = page
        self.chapterTitle = chapterTitle
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // 画像コンテンツ
                Group {
                    if let uiImage = loadedImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                    } else if let url = page.imageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                loadingPlaceholder
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                            case .failure:
                                fallbackPlaceholder
                            @unknown default:
                                loadingPlaceholder
                            }
                        }
                    } else {
                        fallbackPlaceholder
                    }
                }
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale = min(max(scale * delta, 1.0), 4.0)
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            if scale < 1.05 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    scale = 1.0
                                    offset = .zero
                                }
                            }
                        }
                )
                .simultaneousGesture(
                    TapGesture(count: 2).onEnded {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            if scale > 1.2 {
                                scale = 1.0
                                offset = .zero
                            } else {
                                scale = 2.5
                            }
                        }
                    }
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
    
    private var loadingPlaceholder: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
            Text("ページ \(page.pageIndex) 読み込み中...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private var fallbackPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(.horizontal, 16)
            
            VStack(spacing: 16) {
                Image(systemName: page.imageName ?? "book.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(chapterTitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                
                Text("PAGE \(page.pageIndex)")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
        .aspectRatio(page.aspectRatio, contentMode: .fit)
    }
}
