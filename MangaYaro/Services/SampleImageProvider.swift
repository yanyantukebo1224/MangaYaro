import Foundation
import SwiftUI

/// 高画質サンプル画像を生成するURLヘルパー
public struct SampleImageProvider {
    /// ページインデックスとキーワードに基づいた高品質なマンガページ風画像のURL
    public static func pageURL(seed: String, pageIndex: Int, width: Int = 800, height: Int = 1131) -> URL? {
        let uniqueSeed = "\(seed)-\(pageIndex)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "\(pageIndex)"
        return URL(string: "https://picsum.photos/seed/\(uniqueSeed)/\(width)/\(height)")
    }
    
    /// 表紙カバー画像のURL
    public static func coverURL(seed: String, width: Int = 400, height: Int = 600) -> URL? {
        let uniqueSeed = "\(seed)-cover".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "cover"
        return URL(string: "https://picsum.photos/seed/\(uniqueSeed)/\(width)/\(height)")
    }
}
