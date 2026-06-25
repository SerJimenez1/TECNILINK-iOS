import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = (int >> 16) & 0xFF
        let g = (int >> 8) & 0xFF
        let b = int & 0xFF
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }

    static let tecniPrimary = Color(hex: "1A3C6E")
    static let tecniAccent  = Color(hex: "028090")
    static let tecniMint    = Color(hex: "02C39A")
    static let tecniGray    = Color(hex: "64748B")
}
