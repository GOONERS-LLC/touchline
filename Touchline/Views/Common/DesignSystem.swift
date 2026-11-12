//
//  DesignSystem.swift
//  Touchline
//
//  Shared building blocks for a consistent look: cards, section headers,
//  rating badges, two-sided stat bars, pills and club-coloured banners.
//

import SwiftUI

// MARK: - Card

/// The standard surface: rounded, softly separated from the background.
struct GFCard: ViewModifier {
    var padding: CGFloat = 12
    @Environment(\.stadiumTheme) private var stadium
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(stadium ? Color.gfSurface : Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
    }
}

extension View {
    func gfCard(padding: CGFloat = 12) -> some View { modifier(GFCard(padding: min(padding, 12))) }
}

// MARK: - Section header

struct GFSectionHeader<Trailing: View>: View {
    let title: String
    var icon: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.accentColor)
            }
            Text(title)
                .font(.headline)
            Spacer()
            trailing()
        }
        .accessibilityAddTraits(.isHeader)
    }
}

extension GFSectionHeader where Trailing == EmptyView {
    init(title: String, icon: String? = nil) {
        self.init(title: title, icon: icon, trailing: { EmptyView() })
    }
}

// MARK: - Rating badge

/// Overall rating in a coloured tile: gold, silver or bronze by tier.
struct RatingBadge: View {
    let rating: Int
    var size: CGFloat = 32

    static func color(for rating: Int) -> Color {
        switch rating {
        case 85...: return Color(hex: "D4AF37")
        case 78..<85: return Color(hex: "2ECC71")
        case 70..<78: return Color(hex: "3498DB")
        case 60..<70: return Color(hex: "95A5A6")
        default: return Color(hex: "B87333")
        }
    }

    var body: some View {
        Text("\(rating)")
            .font(.system(size: size * 0.45, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .fill(RatingBadge.color(for: rating).gradient)
            )
            .accessibilityLabel("Rated \(rating)")
    }
}

// MARK: - Pill

struct GFPill: View {
    let text: String
    var color: Color = .accentColor
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon) }
            Text(text)
        }
        .font(.caption2.weight(.bold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(color)
        .background(color.opacity(0.14), in: Capsule())
    }
}

// MARK: - Two-sided stat bar

/// "Possession 52% ███████|█████ 48%": the bar splits by share.
struct DualStatBar: View {
    let title: String
    let home: Double
    let away: Double
    var homeText: String
    var awayText: String
    var homeColor: Color = .accentColor
    var awayColor: Color = .orange

    var body: some View {
        let total = max(home + away, 0.0001)
        VStack(spacing: 4) {
            HStack {
                Text(homeText).font(.subheadline.weight(.bold).monospacedDigit())
                Spacer()
                Text(title).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(awayText).font(.subheadline.weight(.bold).monospacedDigit())
            }
            GeometryReader { geo in
                HStack(spacing: 3) {
                    Capsule().fill(homeColor.opacity(home >= away ? 1 : 0.45))
                        .frame(width: max(4, (geo.size.width - 3) * home / total))
                    Capsule().fill(awayColor.opacity(away > home ? 1 : 0.45))
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(homeText) to \(awayText)")
    }
}

// MARK: - Club banner

/// A gradient in the club's colours, used behind headers.
struct ClubGradient: View {
    let club: Club
    var body: some View {
        LinearGradient(
            colors: [Color(hex: club.primaryColor), Color(hex: club.primaryColor).opacity(0.75), Color(hex: club.secondaryColor).opacity(0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// Picks white or black text for legibility on a club colour.
extension Color {
    static func readable(on hex: String) -> Color {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else { return .white }
        let r = Double((value >> 16) & 0xFF), g = Double((value >> 8) & 0xFF), b = Double(value & 0xFF)
        let luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
        return luminance > 0.62 ? .black : .white
    }
}

// MARK: - Stadium theme

/// Whether the dark "stadium at night" look is on (Settings → Appearance).
private struct StadiumThemeKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var stadiumTheme: Bool {
        get { self[StadiumThemeKey.self] }
        set { self[StadiumThemeKey.self] = newValue }
    }
}

extension Color {
    /// Deep navy night sky.
    static let gfNight = Color(hex: "0B1B33")
    /// Slightly lighter navy for surfaces.
    static let gfNavy = Color(hex: "13294B")
    /// Card surface on the stadium background.
    static let gfSurface = Color(hex: "16305A").opacity(0.78)
    /// Hairline on navy surfaces.
    static let gfStroke = Color.white.opacity(0.10)
    /// The positive money / "good" green used on value pills.
    static let gfMint = Color(hex: "7FD99A")
    /// Negative value pill.
    static let gfCoral = Color(hex: "F2727F")
    /// Owner-mode event banner.
    static let gfBanner = Color(hex: "F7A731")
}

/// A floodlit stadium at night: navy sky, two light glows, dark stands and
/// a striped pitch at the bottom. Drawn entirely in SwiftUI.
struct StadiumBackground: View {
    @Environment(\.stadiumTheme) private var stadium

    var body: some View {
        if stadium {
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                ZStack {
                    LinearGradient(colors: [Color(hex: "0A1830"), Color(hex: "102A50"), Color(hex: "0E2546")],
                                   startPoint: .top, endPoint: .bottom)
                    // Floodlights.
                    ForEach([0.0, 1.0], id: \.self) { side in
                        RadialGradient(colors: [Color.white.opacity(0.22), Color(hex: "6FA8FF").opacity(0.10), .clear],
                                       center: .center, startRadius: 2, endRadius: w * 0.45)
                            .frame(width: w * 0.9, height: w * 0.9)
                            .position(x: side == 0 ? -w * 0.02 : w * 1.02, y: h * 0.42)
                    }
                    // Stands.
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(hex: "0C1F3D").opacity(0), Color(hex: "081428").opacity(0.85)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(height: h * 0.16)
                        .position(x: w / 2, y: h * 0.58)
                    // Pitch.
                    VStack(spacing: 0) {
                        ForEach(0..<6, id: \.self) { i in
                            Rectangle().fill(i.isMultiple(of: 2) ? Color(hex: "1E6B3A") : Color(hex: "1A5F33"))
                        }
                    }
                    .frame(height: h * 0.34)
                    .overlay(LinearGradient(colors: [Color(hex: "0E2546").opacity(0.9), Color.black.opacity(0.15), Color.black.opacity(0.55)],
                                            startPoint: .top, endPoint: .bottom))
                    .position(x: w / 2, y: h - h * 0.17)
                }
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
        } else {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
        }
    }
}

extension View {
    /// Puts the stadium behind a screen, including behind lists and forms.
    func stadiumBackground() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(StadiumBackground())
    }
}

// MARK: - Display type

extension Font {
    /// Heavy condensed capitals for titles, like a stadium scoreboard.
    static func gfDisplay(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black).width(.condensed)
    }
    /// Small bold condensed labels for tabs, chips and buttons.
    static func gfLabel(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .heavy).width(.condensed)
    }
}

/// "TRANSFER MARKET" with an optional subtitle, centred.
struct GFScreenTitle: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(.gfDisplay(19))
                .multilineTextAlignment(.center)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Capsule tabs

/// A capsule track of options; the selected one is a white pill.
struct GFTabs<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(value: Value, title: String)]
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                let selected = option.value == selection
                Button {
                    withAnimation(.snappy(duration: 0.22)) { selection = option.value }
                } label: {
                    Text(option.title.uppercased())
                        .font(.gfLabel(compact ? 11 : 12))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, compact ? 5 : 7)
                        .foregroundStyle(selected ? Color.gfNight : Color.white)
                        .background(selected ? Capsule().fill(Color.white) : Capsule().fill(Color.clear))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.title)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(2)
        .background(Capsule().fill(Color.gfNavy.opacity(0.92)))
        .overlay(Capsule().stroke(Color.gfStroke, lineWidth: 1))
    }
}

extension GFTabs where Value: CaseIterable & RawRepresentable, Value.RawValue == String, Value.AllCases: RandomAccessCollection {
    init(selection: Binding<Value>, compact: Bool = false) {
        self.init(selection: selection, options: Value.allCases.map { ($0, $0.rawValue) }, compact: compact)
    }
}

// MARK: - Buttons

/// Big capsule call to action: "PLAY VS NOTTINGHAM", "CONFIRM".
struct GFCapsuleButtonStyle: ButtonStyle {
    enum Kind { case primary, solid, outline, danger }
    var kind: Kind = .primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.gfLabel(15))
            .textCase(.uppercase)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .foregroundStyle(foreground)
            .background(Capsule().fill(fill))
            .overlay(Capsule().stroke(stroke, lineWidth: kind == .primary ? 2 : 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }

    private var fill: Color {
        switch kind {
        case .primary: return Color(hex: "3D7A5C")
        case .solid: return .white
        case .outline: return Color.gfNavy.opacity(0.6)
        case .danger: return Color.gfCoral.opacity(0.25)
        }
    }
    private var foreground: Color {
        switch kind {
        case .primary: return .white
        case .solid: return .gfNight
        case .outline: return .white
        case .danger: return .gfCoral
        }
    }
    private var stroke: Color {
        switch kind {
        case .primary: return Color.white.opacity(0.85)
        case .solid: return .clear
        case .outline: return Color.white.opacity(0.75)
        case .danger: return Color.gfCoral
        }
    }
}

extension ButtonStyle where Self == GFCapsuleButtonStyle {
    static var gfPrimary: GFCapsuleButtonStyle { GFCapsuleButtonStyle(kind: .primary) }
    static var gfSolid: GFCapsuleButtonStyle { GFCapsuleButtonStyle(kind: .solid) }
    static var gfOutline: GFCapsuleButtonStyle { GFCapsuleButtonStyle(kind: .outline) }
    static var gfDanger: GFCapsuleButtonStyle { GFCapsuleButtonStyle(kind: .danger) }
}

// MARK: - Value pill

/// "BANK BALANCE  [€148M]": a caption over a coloured capsule.
struct GFValuePill: View {
    let title: String
    let value: String
    var tone: Tone = .neutral

    enum Tone { case good, bad, neutral }

    var body: some View {
        VStack(spacing: 3) {
            Text(title.uppercased())
                .font(.gfLabel(11))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.gfLabel(12).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(Color.gfNight)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
                .background(Capsule().fill(tone == .good ? Color.gfMint : (tone == .bad ? Color.gfCoral : Color.white)))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Tile

/// A square-ish navy tile with an icon, a caption and an optional badge.
struct GFTile: View {
    let title: String
    let icon: String
    var badge: Int = 0

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .overlay(alignment: .topTrailing) {
                    if badge > 0 {
                        Text("\(min(badge, 99))")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Capsule().fill(Color.red))
                            .offset(x: 12, y: -8)
                    }
                }
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.gfSurface))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.gfStroke, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(badge > 0 ? "\(title), \(badge) new" : title)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Event card (chairman style)

/// A decision or news card: an amber title band, an optional portrait or
/// icon above it, and the body below. Used for the owner's weekly events.
struct GFEventCard<Content: View>: View {
    let title: String
    var icon: String? = nil
    var faceSeed: UInt64? = nil
    var faceTitle: String? = nil
    var faceSubtitle: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            if faceSeed != nil || icon != nil {
                HStack(alignment: .bottom, spacing: 14) {
                    if let faceSeed {
                        FaceView(seed: faceSeed, size: 52, style: .full)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 40, height: 40)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        if let faceTitle { Text(faceTitle).font(.gfDisplay(17)).foregroundStyle(.white) }
                        if let faceSubtitle { Text(faceSubtitle).font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.85)) }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
            }
            Text(title.uppercased())
                .font(.gfDisplay(16))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(hex: "1B1B1B"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.gfBanner)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.gfSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.gfStroke, lineWidth: 1))
    }
}

/// "The manager thinks…" — an advisor's remark beside their face.
struct GFAdvisorBubble: View {
    var faceSeed: UInt64?
    let text: String
    var tone: Color = Color(hex: "3E8E41")

    var body: some View {
        HStack(spacing: 12) {
            if let faceSeed {
                FaceView(seed: faceSeed, size: 34)
            } else {
                Image(systemName: "person.crop.circle.fill").font(.largeTitle)
            }
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(tone))
        .accessibilityElement(children: .combine)
    }
}

/// One option in a list of choices: white row, highlighted when chosen.
struct GFChoiceRow: View {
    let title: String
    var detail: String? = nil
    var selected: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            Text(title).font(.subheadline.weight(.semibold))
            if let detail { Text(detail).font(.caption).foregroundStyle(selected ? Color.white.opacity(0.85) : Color.secondary) }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .padding(.horizontal, 8)
        .foregroundStyle(selected ? Color.white : Color.primary)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(selected ? Color(hex: "3D7A5C") : Color(UIColor.systemBackground).opacity(0.92)))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(selected ? Color.white : Color.clear, lineWidth: 2))
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Group box

/// GroupBox as a navy card with a condensed capital title.
struct GFGroupBoxStyle: GroupBoxStyle {
    @Environment(\.stadiumTheme) private var stadium
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.label
                .font(.gfLabel(13))
                .textCase(.uppercase)
            configuration.content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(stadium ? Color.gfSurface : Color(UIColor.secondarySystemGroupedBackground)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.gfStroke, lineWidth: 1))
    }
}
