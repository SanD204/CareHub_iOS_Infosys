import SwiftUI

struct FontSizeManager {
    @AppStorage("isLargeFontEnabled") static var isLargeFontEnabled: Bool = false
    
    static func fontSize(for baseSize: CGFloat) -> CGFloat {
        isLargeFontEnabled ? baseSize * 1.25 : baseSize
    }
    
    static func font(for baseSize: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: fontSize(for: baseSize), weight: weight)
    }
}

