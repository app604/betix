import SwiftUI

// MARK: - Palette (defined by the brief, do not substitute)
// Background: deep dark blue #0B0F1A
// Accent: electric blue #4A7DFF
// Secondary accent: soft purple #7C5CFF
// Neutrals: cold grays #AAB2C0, #1A2233

enum Palette {
    static let bg          = Color(hex: "0B0F1A")
    static let bgElevated  = Color(hex: "0E1424")
    static let surface     = Color(hex: "1A2233")
    static let accent      = Color(hex: "4A7DFF")   // electric blue
    static let accent2     = Color(hex: "7C5CFF")   // soft purple
    static let cyan        = Color(hex: "34D3E0")   // cool third tone for charts

    static let textPrimary   = Color(hex: "EEF2FA")
    static let textSecondary = Color(hex: "AAB2C0")
    static let textFaint     = Color(hex: "6B7689")

    static let stroke   = Color.white.opacity(0.08)
    static let positive = Color(hex: "4ADE9E")
    static let warn     = Color(hex: "F0A24A")

    static var accentGradient: LinearGradient {
        LinearGradient(colors: [accent, accent2],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var ringGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [accent2, accent, cyan, accent2]),
            center: .center
        )
    }
}

// MARK: - Type ramp
enum AppFont {
    static func display(_ size: CGFloat = 30) -> Font { .system(size: size, weight: .bold, design: .default) }
    static func title(_ size: CGFloat = 20) -> Font { .system(size: size, weight: .semibold, design: .default) }
    static func body(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .regular, design: .default) }
    static func label(_ size: CGFloat = 13) -> Font { .system(size: size, weight: .medium, design: .default) }
    /// Large numeric readouts — rounded design, à la Apple Fitness.
    static func metric(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Ambient background
struct AppBackground: View {
    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()

            // Soft electric-blue bloom, top-leading
            Circle()
                .fill(Palette.accent.opacity(0.22))
                .frame(width: 360, height: 360)
                .blur(radius: 130)
                .offset(x: -120, y: -260)

            // Soft purple bloom, bottom-trailing
            Circle()
                .fill(Palette.accent2.opacity(0.18))
                .frame(width: 400, height: 400)
                .blur(radius: 150)
                .offset(x: 150, y: 320)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Hex helper
extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r, g, b, a: Double
        switch cleaned.count {
        case 8:
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        default:
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
