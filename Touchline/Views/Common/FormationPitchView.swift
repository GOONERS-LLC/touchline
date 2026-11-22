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

    /// A horizontal role column used to separate players sharing a line.
    private enum Lane {
        case gk, leftCenter, center, rightCenter, left, right, leftInner, rightInner

        var x: CGFloat {
            switch self {
            case .gk: return 0.50
            case .leftCenter: return 0.36
            case .center: return 0.50
            case .rightCenter: return 0.64
            case .leftInner: return 0.28
            case .rightInner: return 0.72
            case .left: return 0.14
            case .right: return 0.86
            }
        }
    }

    private struct Slot {
        let lane: Lane
        let depth: CGFloat   // 0 (own goal line) ... 1 (near halfway/attack)
    }

    /// Returns up to 11 slot coordinates, ordered to match `formation.defaultPositions`.
    static func slots(for formation: FormationPreset) -> [CGPoint] {
        let positions = formation.defaultPositions
        let raw: [Slot] = positions.map { slot(for: $0) }
        // Rows run from the goalkeeper (bottom) to the strikers (top), with
        // enough height between them that a token, its name and its rating
        // never overlap the row in front.
        return raw.map { CGPoint(x: $0.lane.x, y: 0.88 - $0.depth) }
    }

    /// Maps a position in a formation to a lane + depth. Depth is derived from the
    /// position's category so lines stay visually separated.
    private static func slot(for position: Position) -> Slot {
        switch position {
        case .GK:
            return Slot(lane: .gk, depth: 0.0)

        case .CB:
            return Slot(lane: .center, depth: 0.17)
        case .LB:
            return Slot(lane: .left, depth: 0.19)
        case .RB:
            return Slot(lane: .right, depth: 0.19)
        case .LWB:
            return Slot(lane: .left, depth: 0.30)
        case .RWB:
            return Slot(lane: .right, depth: 0.30)

        case .CDM:
            return Slot(lane: .center, depth: 0.32)
        case .CM:
            return Slot(lane: .center, depth: 0.44)
        case .LM:
            return Slot(lane: .left, depth: 0.44)
        case .RM:
            return Slot(lane: .right, depth: 0.44)
        case .CAM:
            return Slot(lane: .center, depth: 0.56)

        case .LW:
            return Slot(lane: .left, depth: 0.64)
        case .RW:
            return Slot(lane: .right, depth: 0.64)
        case .CF:
            return Slot(lane: .center, depth: 0.64)
        case .ST:
            return Slot(lane: .center, depth: 0.76)
        }
    }

    /// The formation as lines of slot indices, attack first and goalkeeper
    /// last, each line ordered left to right. The lines come from the
    /// formation's name, so a 4-3-3 shows four, three and three (grouping by
    /// how far up the pitch each position sits made it look like 4-1-2-2-1).
    static func rows(for formation: FormationPreset) -> [[Int]] {
        let positions = formation.defaultPositions
        var rows: [[Int]] = [[0]]
        var next = 1
        for count in formation.lines {
            let end = min(positions.count, next + count)
            if next < end { rows.append(Array(next..<end)) }
            next = end
        }
        if next < positions.count { rows.append(Array(next..<positions.count)) }
        return rows
            .map { line in line.sorted { (side(positions[$0]), $0) < (side(positions[$1]), $1) } }
            .reversed()
    }

    /// Left (0), centre (1) or right (2), to order a line across the pitch.
    private static func side(_ position: Position) -> Int {
        switch position {
        case .LB, .LWB, .LM, .LW: return 0
        case .RB, .RWB, .RM, .RW: return 2
        default: return 1
        }
    }
    /// Spreads players who share a lane and a row evenly and symmetrically
    /// around that lane (two centre-backs sit either side of centre rather
    /// than both drifting to the right).
    static func resolvedSlots(for formation: FormationPreset) -> [CGPoint] {
        var points = slots(for: formation)
        var groups: [String: [Int]] = [:]
        for i in points.indices {
            let key = "\(Int((points[i].y * 100).rounded()))|\(Int((points[i].x * 100).rounded()))"
            groups[key, default: []].append(i)
        }
        for members in groups.values where members.count > 1 {
            let n = CGFloat(members.count)
            let spacing: CGFloat = n >= 3 ? 0.18 : 0.22
            for (k, i) in members.enumerated() {
                let offset = (CGFloat(k) - (n - 1) / 2) * spacing
                points[i].x = min(0.9, max(0.1, points[i].x + offset))
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
    public let onSelect: (Player) -> Void

    public init(
        formation: FormationPreset,
        players: [Player],
        selectedPlayerId: UUID?,
        onSelect: @escaping (Player) -> Void
    ) {
        self.formation = formation
        self.players = players
        self.selectedPlayerId = selectedPlayerId
        self.onSelect = onSelect
    }

    public var body: some View {
        let rows = FormationLayout.rows(for: formation)
        let positions = formation.defaultPositions
        // Lines of cards, strikers at the top and the goalkeeper at the
        // bottom. Plain stacks (no coordinates), so VoiceOver moves through
        // the side in the same order it appears: top to bottom, left to right.
        return VStack(spacing: 12) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { index in
                        if index < players.count {
                            let player = players[index]
                            PlayerPitchCard(
                                player: player,
                                slot: index < positions.count ? positions[index] : player.primaryPosition,
                                isSelected: player.id == selectedPlayerId,
                                width: 84
                            )
                            .onTapGesture { onSelect(player) }
                            .accessibilityAddTraits(player.id == selectedPlayerId ? [.isSelected, .isButton] : .isButton)
                            .accessibilityHint("Double tap to select, then double tap another player to swap")
                            .accessibilityAction { onSelect(player) }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background(
            Canvas { context, canvasSize in
                drawPitch(in: &context, size: canvasSize)
            }
            .accessibilityHidden(true)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
        )
        .transaction { $0.animation = nil }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Starting eleven, \(formation.rawValue)")
    }

    private func drawPitch(in context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height

        let stripeCount = 8
        for i in 0..<stripeCount {
            let rect = CGRect(x: 0, y: h * CGFloat(i) / CGFloat(stripeCount), width: w, height: h / CGFloat(stripeCount))
            let color = i % 2 == 0 ? Color(hex: "3E8F63") : Color(hex: "367F58")
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
    }
}

// MARK: - Player card

/// A lineup card: the position being played, rating, a form arrow, the
/// name and a fitness bar. Pure text and colour, so VoiceOver reads it
/// as one clear sentence.
public struct PlayerPitchCard: View {
    public let player: Player
    public var slot: Position?
    public var isSelected: Bool = false
    public var width: CGFloat = 72
    /// Settings → show the match rating (fitness, form, morale) instead of the base rating.
    @AppStorage("gfShowMatchRating") private var showMatchRating = false

    public init(player: Player, slot: Position? = nil, isSelected: Bool = false, width: CGFloat = 72) {
        self.player = player
        self.slot = slot
        self.isSelected = isSelected
        self.width = width
    }

    private var position: Position { slot ?? player.primaryPosition }
    private var outOfPosition: Bool { !player.positions.contains(position) }

    /// Recent form from the last few match ratings: rising, steady or falling.
    private var trend: (icon: String, color: Color, words: String) {
        let recent = player.form.suffix(3)
        guard !recent.isEmpty else {
            switch player.morale {
            case .delighted, .happy: return ("arrow.up.right", Color(hex: "7FD99A"), "morale high")
            case .unhappy, .furious: return ("arrow.down.right", Color(hex: "F2727F"), "morale low")
            default: return ("arrow.right", Color(hex: "FFC857"), "morale steady")
            }
        }
        let avg = recent.reduce(0, +) / Double(recent.count)
        if avg >= 7.2 { return ("arrow.up", Color(hex: "7FD99A"), "in great form") }
        if avg >= 6.7 { return ("arrow.up.right", Color(hex: "7FD99A"), "in good form") }
        if avg >= 6.2 { return ("arrow.right", Color(hex: "FFC857"), "in steady form") }
        if avg >= 5.8 { return ("arrow.down.right", Color(hex: "F2727F"), "in poor form") }
        return ("arrow.down", Color(hex: "F2727F"), "badly out of form")
    }

    private var fitnessColor: Color {
        player.matchFitness >= 85 ? Color(hex: "7FD99A") : player.matchFitness >= 70 ? .orange : Color(hex: "F2727F")
    }

    public var body: some View {
        let t = trend
        let stats = player.seasonStats
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Text(position.abbreviation)
                    .font(.system(size: 12, weight: .black).width(.condensed))
                    .foregroundStyle(Color(hex: "103036"))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 5).fill(chipColor))
                Spacer(minLength: 0)
                Text("\(shownRating)")
                    .font(.system(size: 13, weight: .black).width(.condensed).monospacedDigit())
                    .foregroundStyle(ratingColor)
            }
            HStack(spacing: 4) {
                Image(systemName: t.icon)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(t.color)
                if player.isInjured || player.isSuspended {
                    Image(systemName: player.isInjured ? "cross.case.fill" : "rectangle.portrait.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                }
            }
            HStack(spacing: 5) {
                if player.primaryPosition == .GK {
                    // Keepers: clean sheets.
                    if stats.cleanSheets > 0 {
                        Label("\(stats.cleanSheets)", systemImage: "hand.raised.fill")
                    }
                } else {
                    if stats.goals > 0 {
                        Label("\(stats.goals)", systemImage: "soccerball")
                    }
                    if stats.assists > 0 {
                        Label("\(stats.assists)", systemImage: "shoe.fill")
                    }
                }
            }
            .labelStyle(TightLabelStyle())
            .font(.system(size: 10, weight: .heavy).width(.condensed))
            .foregroundStyle(.white)
            .frame(height: 12)
            Text(player.lastName.uppercased())
                .font(.system(size: 12, weight: .black).width(.condensed))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.18))
                    Capsule().fill(fitnessColor)
                        .frame(width: geo.size.width * max(0, min(1, player.matchFitness / 100)))
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 7)
        .frame(minWidth: 58, maxWidth: width)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: "15393F"), Color(hex: "0F2D32")], startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isSelected ? Color.white : Color.white.opacity(0.18), lineWidth: isSelected ? 3 : 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    /// Chip colour by role: keepers green, defenders yellow, midfielders
    /// orange, forwards red. Orange-red warns of a player out of position.
    private var chipColor: Color {
        if outOfPosition { return Color(hex: "FF8A3D") }
        switch position.category {
        case .goalkeeper: return Color(hex: "86D69A")
        case .defender: return Color(hex: "F2D15C")
        case .midfielder: return Color(hex: "F4B45F")
        case .forward: return Color(hex: "F27C7C")
        }
    }

    private var shownRating: Int { showMatchRating ? player.matchRating : player.overall }

    private var ratingColor: Color {
        guard showMatchRating else { return .white }
        if player.matchRating > player.overall { return Color(hex: "7FD99A") }
        if player.matchRating < player.overall { return Color(hex: "F2727F") }
        return .white
    }

    private var ratingWords: String {
        showMatchRating ? "match rating \(player.matchRating), base \(player.overall)" : "rated \(player.overall)"
    }

    /// "Left back: Andy Robertson, rated 84, in good form, fitness 92 percent."
    var spoken: String {
        var parts = ["\(position.displayName): \(player.fullName)", ratingWords, trend.words,
                     "fitness \(Int(player.matchFitness)) percent"]
        if outOfPosition { parts.append("playing out of position, usually \(player.primaryPosition.displayName)") }
        if player.primaryPosition == .GK {
            if player.seasonStats.appearances > 0 {
                parts.append("\(player.seasonStats.cleanSheets) clean sheets, \(player.seasonStats.goalsConceded) conceded")
            }
        } else {
            if player.seasonStats.goals > 0 { parts.append("\(player.seasonStats.goals) goals") }
            if player.seasonStats.assists > 0 { parts.append("\(player.seasonStats.assists) assists") }
        }
        if player.isInjured { parts.append("injured") }
        if player.isSuspended { parts.append("suspended") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Player Token

public struct PlayerTokenView: View {
    public let player: Player
    public let isSelected: Bool

    public init(player: Player, isSelected: Bool) {
        self.player = player
        self.isSelected = isSelected
    }

    public var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.35))
                    .frame(width: 38, height: 38)
                FaceView(player: player, size: 34)
                    .clipShape(Circle())
                    .frame(width: 34, height: 34)
                Circle()
                    .stroke(player.primaryPosition.category.accentColor, lineWidth: 2.5)
                    .frame(width: 38, height: 38)
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 46, height: 46)
                        .shadow(color: .white.opacity(0.6), radius: 4)
                }
                if player.isInjured || player.isSuspended {
                    Image(systemName: player.isInjured ? "cross.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.white, .red)
                        .offset(x: 16, y: -15)
                }
            }
            Text(player.displayName)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 78)
            HStack(spacing: 3) {
                Text(player.primaryPosition.abbreviation)
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.85))
                Text("\(player.overall)")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 3)
                    .background(RatingBadge.color(for: player.overall), in: RoundedRectangle(cornerRadius: 3))
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


/// One player as a full-width button: used for VoiceOver lineups.
struct AccessibleLineupRow: View {
    let player: Player
    var slot: Position?
    var isSelected: Bool = false
    var hint: String = "Double tap to select. Then double tap another player to swap them."
    let action: () -> Void

    var body: some View {
        let card = PlayerPitchCard(player: player, slot: slot, isSelected: isSelected)
        Button(action: action) {
            HStack(spacing: 10) {
                Text((slot ?? player.primaryPosition).abbreviation)
                    .font(.gfLabel(13))
                    .foregroundStyle(.black)
                    .frame(width: 42)
                    .padding(.vertical, 4)
                    .background(Capsule().fill((slot ?? player.primaryPosition).category.accentColor))
                Text(player.fullName).font(.body.weight(.semibold)).lineLimit(1)
                Spacer()
                Text("\(player.overall)").font(.gfLabel(15).monospacedDigit())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? Color.white.opacity(0.25) : Color.gfSurface))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(card.spoken)
        .accessibilityHint(hint)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}


/// An icon-and-number label with almost no gap: "1⚽".
struct TightLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 1) {
            configuration.title
            configuration.icon
        }
    }
}
