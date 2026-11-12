//
//  FormationPitchView.swift
//  Touchline
//
//  Interactive top-down formation board for the squad screen. Draws the current
//  formation as a pitch with a token for each starting player. Tapping a token
//  selects that player so they can be swapped with a substitute (manager mode).
//

import SwiftUI

// MARK: - Formation Layout

/// Computes normalised (0...1) slot coordinates for each position in a formation.
/// Coordinates run from the user's own goal (y = 1.0, bottom) to the opponent goal
/// (y = 0.0, top), i.e. an attacking-first orientation.
enum FormationLayout {
    /// Lateral preference: 0 is the left touchline, 1 the right, 0.5 central.
    private static func lateral(_ p: Position) -> CGFloat {
        switch p {
        case .LB, .LWB, .LM, .LW: return 0
        case .RB, .RWB, .RM, .RW: return 1
        default: return 0.5
        }
    }

    /// Small vertical nudges inside a line so holding players sit a touch
    /// deeper and playmakers a touch higher, without breaking the line.
    private static func nudge(_ p: Position) -> CGFloat {
        switch p {
        case .CDM: return 0.035
        case .CAM, .CF: return -0.03
        case .LW, .RW: return -0.015
        case .LWB, .RWB: return -0.02
        default: return 0
        }
    }

    /// Defensive weight used to place the deepest central player in the middle of a line.
    private static func depthRank(_ p: Position) -> Int {
        switch p {
        case .CB: return 0
        case .CDM: return 1
        case .CM: return 2
        case .CAM: return 3
        case .CF: return 4
        case .ST: return 5
        default: return 2
        }
    }

    /// Returns 11 slot coordinates (0...1, own goal at the bottom), ordered to
    /// match `formation.defaultPositions`. Players are grouped into the
    /// formation's real lines (4-3-3 draws as four, three, three), wide players
    /// sit on the flanks and central players spread evenly between them.
    static func resolvedSlots(for formation: FormationPreset) -> [CGPoint] {
        let positions = formation.defaultPositions
        var points = Array(repeating: CGPoint(x: 0.5, y: 0.9), count: positions.count)
        guard !positions.isEmpty else { return points }
        points[0] = CGPoint(x: 0.5, y: 0.915)

        let lines = formation.lines
        let top: CGFloat = 0.13, bottom: CGFloat = 0.74
        var cursor = 1
        for (lineIndex, count) in lines.enumerated() {
            let indices = Array(cursor..<min(positions.count, cursor + count))
            cursor += count
            let y = lines.count == 1 ? (top + bottom) / 2
                : bottom - (bottom - top) * CGFloat(lineIndex) / CGFloat(lines.count - 1)

            // Order: left flank, centrals (deepest in the middle), right flank.
            let left = indices.filter { lateral(positions[$0]) == 0 }
            let right = indices.filter { lateral(positions[$0]) == 1 }
            var central = indices.filter { lateral(positions[$0]) == 0.5 }
                .sorted { depthRank(positions[$0]) > depthRank(positions[$1]) }
            if central.count >= 3 {
                // Put the most defensive central player in the middle.
                let deepest = central.removeLast()
                central.insert(deepest, at: central.count / 2)
            }
            let ordered = left + central + right
            let n = ordered.count
            let margin: CGFloat = n >= 5 ? 0.09 : n == 4 ? 0.13 : n == 3 ? 0.22 : 0.33
            for (i, idx) in ordered.enumerated() {
                let x = n == 1 ? 0.5 : margin + (1 - 2 * margin) * CGFloat(i) / CGFloat(n - 1)
                points[idx] = CGPoint(x: x, y: y + nudge(positions[idx]))
            }
        }
        return points
    }
}

// MARK: - Formation Pitch View

public struct FormationPitchView: View {
    public let formation: FormationPreset
    public let players: [Player]
    public let selectedPlayerId: UUID?
    /// Match ratings to show on each token (post-match Ratings tab).
    public var ratings: [UUID: Double]? = nil
    /// The spoken hint for tapping a token.
    public var tapHint: String = "Double tap to select this player for substitution"
    public let onSelect: (Player) -> Void

    public init(
        formation: FormationPreset,
        players: [Player],
        selectedPlayerId: UUID?,
        ratings: [UUID: Double]? = nil,
        tapHint: String = "Double tap to select this player for substitution",
        onSelect: @escaping (Player) -> Void
    ) {
        self.formation = formation
        self.players = players
        self.selectedPlayerId = selectedPlayerId
        self.ratings = ratings
        self.tapHint = tapHint
        self.onSelect = onSelect
    }

    public var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let slots = FormationLayout.resolvedSlots(for: formation)

            ZStack {
                Canvas { context, canvasSize in
                    drawPitch(in: &context, size: canvasSize)
                }
                .frame(width: size.width, height: size.height)

                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    if index < slots.count {
                        let point = slots[index]
                        let slotPosition = index < formation.defaultPositions.count ? formation.defaultPositions[index] : player.primaryPosition
                        let rating = ratings?[player.id]
                        PlayerTokenView(
                            player: player,
                            isSelected: player.id == selectedPlayerId,
                            slotPosition: slotPosition,
                            rating: rating
                        )
                        .position(x: point.x * size.width, y: point.y * size.height)
                        .onTapGesture { Haptics.selection(); onSelect(player) }
                        .accessibilityLabel(rating.map { "\(player.fullName), \(slotPosition.displayName), match rating \(String(format: "%.1f", $0))" }
                                            ?? "\(player.fullName), playing \(slotPosition.displayName), overall \(player.overall)")
                        .accessibilityAddTraits(player.id == selectedPlayerId ? [.isSelected, .isButton] : .isButton)
                        .accessibilityHint(tapHint)
                    }
                }
            }
        }
        .aspectRatio(68.0 / 105.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(formation.displayName) formation")
    }

    private func drawPitch(in context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height

        let stripeCount = 8
        for i in 0..<stripeCount {
            let rect = CGRect(x: 0, y: h * CGFloat(i) / CGFloat(stripeCount), width: w, height: h / CGFloat(stripeCount))
            let color = i % 2 == 0 ? Color.pitchGrassLight : Color.pitchGrassDark
            context.fill(Path(rect), with: .color(color))
        }

        let lineColor = Color.white.opacity(0.7)
        let lineWidth = max(1.5, w * 0.005)
        let inset = w * 0.03
        let field = CGRect(x: inset, y: inset, width: w - inset * 2, height: h - inset * 2)
        context.stroke(Path(field), with: .color(lineColor), lineWidth: lineWidth)

        var halfway = Path()
        halfway.move(to: CGPoint(x: field.minX, y: field.midY))
        halfway.addLine(to: CGPoint(x: field.maxX, y: field.midY))
        context.stroke(halfway, with: .color(lineColor), lineWidth: lineWidth)

        let circleRadius = field.width * 0.13
        context.stroke(
            Path(ellipseIn: CGRect(x: field.midX - circleRadius, y: field.midY - circleRadius, width: circleRadius * 2, height: circleRadius * 2)),
            with: .color(lineColor),
            lineWidth: lineWidth
        )

        let boxW = field.width * 0.55
        let boxH = field.height * 0.14
        let topBox = CGRect(x: field.midX - boxW / 2, y: field.minY, width: boxW, height: boxH)
        let bottomBox = CGRect(x: field.midX - boxW / 2, y: field.maxY - boxH, width: boxW, height: boxH)
        context.stroke(Path(topBox), with: .color(lineColor), lineWidth: lineWidth)
        context.stroke(Path(bottomBox), with: .color(lineColor), lineWidth: lineWidth)

        let goalW = field.width * 0.28
        let goalH = boxH * 0.42
        let topGoal = CGRect(x: field.midX - goalW / 2, y: field.minY, width: goalW, height: goalH)
        let bottomGoal = CGRect(x: field.midX - goalW / 2, y: field.maxY - goalH, width: goalW, height: goalH)
        context.stroke(Path(topGoal), with: .color(lineColor), lineWidth: lineWidth)
        context.stroke(Path(bottomGoal), with: .color(lineColor), lineWidth: lineWidth)

        // Centre spot, penalty spots and the arcs on the edge of each box.
        let spot = max(2.5, w * 0.008)
        for c in [CGPoint(x: field.midX, y: field.midY),
                  CGPoint(x: field.midX, y: field.minY + boxH * 0.72),
                  CGPoint(x: field.midX, y: field.maxY - boxH * 0.72)] {
            context.fill(Path(ellipseIn: CGRect(x: c.x - spot, y: c.y - spot, width: spot * 2, height: spot * 2)), with: .color(lineColor))
        }
        let arcR = field.width * 0.12
        var topArc = Path()
        topArc.addArc(center: CGPoint(x: field.midX, y: field.minY + boxH * 0.72), radius: arcR,
                      startAngle: .degrees(35), endAngle: .degrees(145), clockwise: false)
        var bottomArc = Path()
        bottomArc.addArc(center: CGPoint(x: field.midX, y: field.maxY - boxH * 0.72), radius: arcR,
                         startAngle: .degrees(215), endAngle: .degrees(325), clockwise: false)
        context.stroke(topArc, with: .color(lineColor), lineWidth: lineWidth)
        context.stroke(bottomArc, with: .color(lineColor), lineWidth: lineWidth)

        // Soft floodlight vignette.
        context.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .radialGradient(Gradient(colors: [.clear, Color.black.opacity(0.35)]),
                                           center: CGPoint(x: w / 2, y: h / 2), startRadius: w * 0.3, endRadius: h * 0.75))
    }
}

// MARK: - Player Token

public struct PlayerTokenView: View {
    public let player: Player
    public let isSelected: Bool
    public var slotPosition: Position? = nil
    public var rating: Double? = nil

    public init(player: Player, isSelected: Bool, slotPosition: Position? = nil, rating: Double? = nil) {
        self.player = player
        self.isSelected = isSelected
        self.slotPosition = slotPosition
        self.rating = rating
    }

    private var role: Position { slotPosition ?? player.primaryPosition }

    private var ratingColor: Color {
        guard let rating else { return Color.surfaceRaised }
        if rating >= 8.0 { return Color(hex: "1E9E62") }
        if rating >= 7.0 { return Color(hex: "2F5BEA") }
        if rating >= 6.0 { return Color(hex: "B7791F") }
        return Color(hex: "C53030")
    }

    public var body: some View {
        VStack(spacing: 3) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [role.category.accentColor, role.category.accentColor.opacity(0.7)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: 36, height: 36)
                        .shadow(color: .black.opacity(0.45), radius: 3, y: 2)
                    Circle()
                        .stroke(isSelected ? Color.white : Color.white.opacity(0.35), lineWidth: isSelected ? 3 : 1)
                        .frame(width: 36, height: 36)
                    Text(role.abbreviation)
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                }
                if let rating {
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(ratingColor)
                        .clipShape(Capsule())
                        .offset(x: 12, y: -6)
                }
            }
            Text(player.lastName.isEmpty ? player.displayName : player.lastName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.ink.opacity(0.75))
                .clipShape(Capsule())
                .lineLimit(1)
                .frame(maxWidth: 78)
            if rating == nil {
                Text("\(player.overall)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.highlight)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Formation") {
    let positions: [Position] = [.GK, .LB, .CB, .CB, .RB, .LM, .CM, .CM, .RM, .ST, .ST]
    let players = positions.enumerated().map { idx, pos in
        Player(
            firstName: "Player",
            lastName: "\(idx + 1)",
            nationality: "England",
            age: 24,
            height: 180,
            weight: 75,
            preferredFoot: .right,
            positions: [pos],
            attributes: PlayerAttributes(),
            overall: 60 + idx,
            potential: 75
        )
    }
    return FormationPitchView(formation: .f442, players: players, selectedPlayerId: players[5].id, onSelect: { _ in })
        .padding()
}
#endif
