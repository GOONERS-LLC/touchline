//
//  DesignSystem.swift
//  Touchline
//
//  Touchline's "Floodlight" design language: deep ink surfaces, cobalt
//  actions, amber highlights, rounded type in sentence case. Every shared
//  component (cards, tabs, buttons, tiles, banners) is defined here.
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
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(stadium ? Color.gfSurface : Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(stadium ? Color.gfStroke : Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}

extension View {
    func gfCard(padding: CGFloat = 14) -> some View { modifier(GFCard(padding: min(max(padding, 14), 16))) }
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
                    .foregroundStyle(Color.highlight)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.highlight.opacity(0.14)))
            }
            Text(title)
                .font(.system(.headline, design: .rounded))
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
        case 85...: return Color(hex: "E09A10")
        case 78..<85: return Color(hex: "1E9E62")
        case 70..<78: return Color(hex: "2F5BEA")
        case 60..<70: return Color(hex: "5B6785")
        default: return Color(hex: "8A5A3C")
        }
    }

    var body: some View {
        Text("\(rating)")
            .font(.system(size: size * 0.45, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                Circle().fill(RatingBadge.color(for: rating).gradient)
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
    var homeColor: Color = .brand
    var awayColor: Color = .highlight

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
    /// Ink: the app background.
    static let gfNight = Color(hex: "0A0F1E")
    /// Raised ink for tracks and panels.
    static let gfNavy = Color(hex: "141C33")
    /// Card surface.
    static let gfSurface = Color(hex: "151E38").opacity(0.94)
    /// Hairline on ink surfaces.
    static let gfStroke = Color(hex: "2B3760")
    /// Positive values.
    static let gfMint = Color(hex: "2BD07F")
    /// Negative values.
    static let gfCoral = Color(hex: "FF5A5F")
    /// Event-card title band (cobalt).
    static let gfBanner = Color(hex: "2F5BEA")
}

/// Touchline's backdrop: deep ink, a cobalt floodlight glow from the top
/// corner, faint pitch markings and an amber touchline along the bottom.
/// Drawn entirely in SwiftUI.
struct StadiumBackground: View {
    @Environment(\.stadiumTheme) private var stadium

    var body: some View {
        if stadium {
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                ZStack {
                    Color(hex: "0A0F1E")
                    RadialGradient(colors: [Color(hex: "2F5BEA").opacity(0.38), Color(hex: "2F5BEA").opacity(0.08), .clear],
                                   center: .topTrailing, startRadius: 10, endRadius: max(w, h) * 0.75)
                    RadialGradient(colors: [Color(hex: "FFB020").opacity(0.10), .clear],
                                   center: .bottomLeading, startRadius: 10, endRadius: w * 0.9)
                    // Faint centre circle and halfway line.
                    Canvas { context, size in
                        let line = Color.white.opacity(0.035)
                        var halfway = Path()
                        halfway.move(to: CGPoint(x: 0, y: size.height * 0.55))
                        halfway.addLine(to: CGPoint(x: size.width, y: size.height * 0.55))
                        context.stroke(halfway, with: .color(line), lineWidth: 2)
                        let r = size.width * 0.32
                        context.stroke(Path(ellipseIn: CGRect(x: size.width / 2 - r, y: size.height * 0.55 - r, width: r * 2, height: r * 2)),
                                       with: .color(line), lineWidth: 2)
                    }
                    // The touchline.
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(hex: "FFB020").opacity(0), Color(hex: "FFB020").opacity(0.55), Color(hex: "FFB020").opacity(0)],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(height: 2)
                        .position(x: w / 2, y: h - 1)
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
        .system(size: size, weight: .bold, design: .rounded)
    }
    /// Small bold condensed labels for tabs, chips and buttons.
    static func gfLabel(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

/// "TRANSFER MARKET" with an optional subtitle, centred.
struct GFScreenTitle: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.gfDisplay(21))
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
        HStack(spacing: 4) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                let selected = option.value == selection
                Button {
                    Haptics.selection()
                    withAnimation(.snappy(duration: 0.22)) { selection = option.value }
                } label: {
                    Text(option.title)
                        .font(.gfLabel(compact ? 12 : 14))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, compact ? 7 : 10)
                        .foregroundStyle(selected ? Color.white : Color.white.opacity(0.65))
                        .background(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill(selected ? Color.brand : Color.clear)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.title)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.gfNavy))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.gfStroke, lineWidth: 1))
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
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .foregroundStyle(foreground)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(kind == .primary
                          ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "3A68F5"), Color(hex: "2447C9")], startPoint: .top, endPoint: .bottom))
                          : AnyShapeStyle(fill))
            )
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(stroke, lineWidth: 1))
            .shadow(color: kind == .primary ? Color(hex: "2F5BEA").opacity(0.35) : .clear, radius: 10, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in if pressed { Haptics.tap() } }
    }

    private var fill: Color {
        switch kind {
        case .primary: return Color(hex: "2F5BEA")
        case .solid: return Color(hex: "FFB020")
        case .outline: return Color.gfNavy
        case .danger: return Color.gfCoral.opacity(0.16)
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
        case .primary: return Color.white.opacity(0.14)
        case .solid: return .clear
        case .outline: return Color.gfStroke
        case .danger: return Color.gfCoral.opacity(0.6)
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
            Text(title)
                .font(.gfLabel(11))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.gfLabel(12).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(Color.gfNight)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(tone == .good ? Color.gfMint : (tone == .bad ? Color.gfCoral : Color.white)))
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
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(hex: "FFB020"))
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color(hex: "FFB020").opacity(0.14)))
                .overlay(alignment: .topTrailing) {
                    if badge > 0 {
                        Text("\(min(badge, 99))")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Capsule().fill(Color.gfCoral))
                            .offset(x: 8, y: -4)
                    }
                }
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 74)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.gfSurface))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.gfStroke, lineWidth: 1))
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
            Text(title)
                .font(.gfDisplay(16))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.white)
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
    var tone: Color = Color(hex: "1D3BA8")

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
        .foregroundStyle(Color.white)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(selected ? Color(hex: "2F5BEA") : Color.gfNavy))
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
                .font(.gfLabel(14))
                .foregroundStyle(Color.highlight)
            configuration.content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(stadium ? Color.gfSurface : Color(UIColor.secondarySystemGroupedBackground)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.gfStroke, lineWidth: 1))
    }
}
