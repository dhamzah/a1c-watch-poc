import SwiftUI

/// Design tokens taken from a1c.io (CSS custom properties, Nov 2026):
/// --a1c-royal-black #030303, --a1c-moroccan-blue #0052ff, --a1c-ultra-white #fafcff,
/// ink scale, --success #17c964, --warning #f5a524, --danger #ff383c,
/// --border #ffffff1f, --bg-elev #0e0f12, display font Chillax, body Inter (SF here), data JetBrains Mono (SF Mono here).
extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255, opacity: alpha)
    }
}

enum A1CColor {
    // Brand
    static let royalBlack = Color(hex: 0x030303)
    static let moroccanBlue = Color(hex: 0x0052FF)
    static let blue500 = Color(hex: 0x3376FF)
    static let blue300 = Color(hex: 0x85ADFF)
    static let ultraWhite = Color(hex: 0xFAFCFF)
    // Surfaces + text
    static let bgElev = Color(hex: 0x0E0F12)
    static let bgMuted = Color(hex: 0x16181C)
    static let border = Color.white.opacity(0.12)
    static let fgMuted = Color(hex: 0x9AA1AE)
    static let ink500 = Color(hex: 0x6A7282)
    // Status
    static let success = Color(hex: 0x17C964)
    static let warning = Color(hex: 0xF5A524)
    static let danger = Color(hex: 0xFF383C)

    // Semantic glucose mapping
    static let inRange = success
    static let high = warning
    static let veryHigh = danger
    static let low = danger
    static let battery = blue500
    static let readiness = blue300
    static let stale = ink500
    static let accent = moroccanBlue

    static func glucose(_ v: Double, t: Thresholds = Thresholds()) -> Color {
        if v < t.low { return low }
        if v > 180 { return veryHigh }
        if v > t.high { return high }
        return inRange
    }
}

enum A1CFont {
    /// Chillax, the a1c.io display face. Falls back to SF if the font failed to register.
    static func display(_ size: CGFloat, _ weight: String = "Medium") -> Font {
        .custom("Chillax-\(weight)", size: size)
    }
    static func body(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
    /// Eyebrow / data label, like the site's JetBrains Mono labels.
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

/// Uppercase mono eyebrow, as used above headings on a1c.io.
struct Eyebrow: View {
    let text: String
    var color: Color = A1CColor.fgMuted
    var body: some View {
        Text(text.uppercased()).font(A1CFont.mono(10)).tracking(0.8).foregroundStyle(color)
    }
}

/// Elevated card: bg-elev fill, 1px white/12% border, 12pt radius.
struct A1CCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(A1CColor.bgElev, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(A1CColor.border, lineWidth: 1))
    }
}

/// Pill button styles from the site: primary Moroccan blue, secondary outlined.
struct A1CPrimaryButton: ButtonStyle {
    var tint: Color = A1CColor.moroccanBlue
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(A1CFont.body(15, .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(tint.opacity(configuration.isPressed ? 0.7 : 1), in: Capsule())
    }
}

struct A1CSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(A1CFont.body(14, .medium))
            .foregroundStyle(A1CColor.ultraWhite)
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(Color.white.opacity(configuration.isPressed ? 0.12 : 0.04), in: Capsule())
            .overlay(Capsule().strokeBorder(A1CColor.border, lineWidth: 1))
    }
}

/// A1C wordmark: the mark plus "A1C" in Chillax, like the site header.
struct A1CWordmark: View {
    var body: some View {
        HStack(spacing: 4) {
            Image("A1CMark").resizable().scaledToFit().frame(width: 16, height: 16)
                .padding(2).background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 5))
            Text("A1C").font(A1CFont.display(15, "Regular")).foregroundStyle(A1CColor.ultraWhite)
        }
    }
}
