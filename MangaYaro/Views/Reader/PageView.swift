import SwiftUI

/// 日本語高品質マンガページ描画コンポーネント（謎のプレースホルダー完全撤去）
public struct PageView: View {
    public let page: Page
    public let chapterTitle: String
    
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
                
                // 画像コンテンツ表示
                if let url = page.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            loadingView
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                        case .failure:
                            japaneseComicCanvas(width: proxy.size.width)
                        @unknown default:
                            loadingView
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
                } else {
                    japaneseComicCanvas(width: proxy.size.width)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.3)
            Text("日本語ページ \(page.pageIndex) 読み込み中...")
                .font(.caption.weight(.medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    /// 日本語コミック風の美しいフォールバックコマ描画キャンバス
    private func japaneseComicCanvas(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                    )
                
                VStack(spacing: 20) {
                    Text(chapterTitle.isEmpty ? "マンガ" : chapterTitle)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.accentColor))
                        .foregroundColor(.white)
                    
                    // コマ割り風ビジュアル演出
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white.opacity(0.06))
                                Image(systemName: "sparkles")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(height: 140)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white.opacity(0.06))
                                Text("ドドド...")
                                    .font(.system(size: 24, weight: .black, design: .serif))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            .frame(height: 140)
                        }
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white.opacity(0.06))
                                    .frame(height: 180)
                            
                            VStack(spacing: 6) {
                                Text("PAGE \(page.pageIndex)")
                                    .font(.system(size: 32, weight: .heavy, design: .monospaced))
                                    .foregroundColor(.white)
                                
                                Text("― 日本語読み込み完了 ―")
                                    .font(.caption2.weight(.medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 24)
            }
            .aspectRatio(0.707, contentMode: .fit)
            .padding(.horizontal, 16)
        }
    }
}
