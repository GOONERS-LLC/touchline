//
//  KitView.swift
//  Touchline
//
//  Draws a full kit (shirt, shorts and socks) from a KitDesign, with the
//  shirt sponsor across the chest, plus the kit designer for owners.
//

import SwiftUI

// MARK: - Kit drawing

public struct KitView: View {
    public let kit: KitDesign
    public var sponsor: String? = nil
    public var monogram: String? = nil
    public var height: CGFloat = 180

    public init(kit: KitDesign, sponsor: String? = nil, monogram: String? = nil, height: CGFloat = 180) {
        self.kit = kit
        self.sponsor = sponsor
        self.monogram = monogram
        self.height = height
    }

    public var body: some View {
        Canvas { context, size in
            let s = size.height / 180
            context.scaleBy(x: s, y: s)
            draw(in: &context)
        }
        .frame(width: height * 100 / 180, height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Kit. \(kit.spokenDescription)\(sponsor.map { " Shirt sponsor \($0)." } ?? "")")
    }

    private func c(_ hex: String) -> Color { Color(hex: hex) }

    // Shirt outline in a 100 x 100 box.
    private var shirtPath: Path {
        var p = Path()
        p.move(to: CGPoint(x: 38, y: 4))
        p.addQuadCurve(to: CGPoint(x: 62, y: 4), control: CGPoint(x: 50, y: 13))
        p.addLine(to: CGPoint(x: 80, y: 9))
        p.addLine(to: CGPoint(x: 99, y: 26))
        p.addLine(to: CGPoint(x: 89, y: 41))
        p.addLine(to: CGPoint(x: 79, y: 33))
        p.addLine(to: CGPoint(x: 79, y: 98))
        p.addQuadCurve(to: CGPoint(x: 21, y: 98), control: CGPoint(x: 50, y: 101))
        p.addLine(to: CGPoint(x: 21, y: 33))
        p.addLine(to: CGPoint(x: 11, y: 41))
        p.addLine(to: CGPoint(x: 1, y: 26))
        p.addLine(to: CGPoint(x: 20, y: 9))
        p.closeSubpath()
        return p
    }

    private var sleevesPath: Path {
        var p = Path()
        p.addLines([CGPoint(x: 20, y: 9), CGPoint(x: 1, y: 26), CGPoint(x: 11, y: 41), CGPoint(x: 21, y: 33), CGPoint(x: 23, y: 12)])
        p.closeSubpath()
        p.addLines([CGPoint(x: 80, y: 9), CGPoint(x: 99, y: 26), CGPoint(x: 89, y: 41), CGPoint(x: 79, y: 33), CGPoint(x: 77, y: 12)])
        p.closeSubpath()
        return p
    }

    private func patternPath() -> Path {
        var p = Path()
        switch kit.pattern {
        case .plain:
            break
        case .stripes:
            var x: CGFloat = 4
            while x < 100 { p.addRect(CGRect(x: x, y: 0, width: 8, height: 100)); x += 16 }
        case .pinstripes:
            var x: CGFloat = 3
            while x < 100 { p.addRect(CGRect(x: x, y: 0, width: 1.4, height: 100)); x += 6 }
        case .hoops:
            var y: CGFloat = 10
            while y < 100 { p.addRect(CGRect(x: 0, y: y, width: 100, height: 10)); y += 20 }
        case .halves:
            p.addRect(CGRect(x: 50, y: 0, width: 50, height: 100))
        case .quarters:
            p.addRect(CGRect(x: 50, y: 0, width: 50, height: 50))
            p.addRect(CGRect(x: 0, y: 50, width: 50, height: 50))
        case .sash:
            p.addLines([CGPoint(x: 18, y: 0), CGPoint(x: 36, y: 0), CGPoint(x: 92, y: 100), CGPoint(x: 74, y: 100)])
            p.closeSubpath()
        case .centreStripe:
            p.addRect(CGRect(x: 38, y: 0, width: 24, height: 100))
        case .chevron:
            p.addLines([CGPoint(x: 0, y: 22), CGPoint(x: 50, y: 48), CGPoint(x: 100, y: 22),
                        CGPoint(x: 100, y: 36), CGPoint(x: 50, y: 62), CGPoint(x: 0, y: 36)])
            p.closeSubpath()
        case .band:
            p.addRect(CGRect(x: 0, y: 40, width: 100, height: 16))
        }
        return p
    }

    private func draw(in context: inout GraphicsContext) {
        let outline = Color.black.opacity(0.45)

        // Shirt
        let shirt = shirtPath
        context.fill(shirt, with: .color(c(kit.primary)))
        context.drawLayer { layer in
            layer.clip(to: shirt)
            layer.fill(patternPath(), with: .color(c(kit.secondary)))
            if kit.contrastSleeves { layer.fill(sleevesPath, with: .color(c(kit.secondary))) }
            // Cuffs
            var cuffs = Path()
            cuffs.addLines([CGPoint(x: 1, y: 26), CGPoint(x: 11, y: 41), CGPoint(x: 13.5, y: 38.5), CGPoint(x: 3.5, y: 23.5)])
            cuffs.closeSubpath()
            cuffs.addLines([CGPoint(x: 99, y: 26), CGPoint(x: 89, y: 41), CGPoint(x: 86.5, y: 38.5), CGPoint(x: 96.5, y: 23.5)])
            cuffs.closeSubpath()
            layer.fill(cuffs, with: .color(c(kit.trim)))
            // Soft fabric shading
            layer.fill(Path(CGRect(x: 0, y: 0, width: 100, height: 100)),
                       with: .linearGradient(Gradient(colors: [Color.white.opacity(0.12), .clear, Color.black.opacity(0.22)]),
                                             startPoint: CGPoint(x: 20, y: 0), endPoint: CGPoint(x: 80, y: 100)))
        }
        context.stroke(shirt, with: .color(outline), lineWidth: 1.2)

        // Collar
        switch kit.collar {
        case .crew:
            var neck = Path()
            neck.move(to: CGPoint(x: 38, y: 4))
            neck.addQuadCurve(to: CGPoint(x: 62, y: 4), control: CGPoint(x: 50, y: 13))
            context.stroke(neck, with: .color(c(kit.trim)), lineWidth: 3.2)
        case .vNeck:
            var v = Path()
            v.addLines([CGPoint(x: 38, y: 4), CGPoint(x: 50, y: 17), CGPoint(x: 62, y: 4)])
            context.stroke(v, with: .color(c(kit.trim)), style: StrokeStyle(lineWidth: 3.2, lineJoin: .round))
        case .polo:
            var left = Path(), right = Path()
            left.addLines([CGPoint(x: 37, y: 3), CGPoint(x: 49, y: 7), CGPoint(x: 44, y: 15)]); left.closeSubpath()
            right.addLines([CGPoint(x: 63, y: 3), CGPoint(x: 51, y: 7), CGPoint(x: 56, y: 15)]); right.closeSubpath()
            context.fill(left, with: .color(c(kit.trim)))
            context.fill(right, with: .color(c(kit.trim)))
            context.stroke(left, with: .color(outline), lineWidth: 0.6)
            context.stroke(right, with: .color(outline), lineWidth: 0.6)
        }

        // Badge on the left chest
        var badge = Path()
        badge.addLines([CGPoint(x: 62, y: 20), CGPoint(x: 72, y: 20), CGPoint(x: 72, y: 27), CGPoint(x: 67, y: 32), CGPoint(x: 62, y: 27)])
        badge.closeSubpath()
        context.fill(badge, with: .color(c(kit.trim)))
        context.stroke(badge, with: .color(outline), lineWidth: 0.6)
        if let monogram, !monogram.isEmpty {
            context.draw(Text(String(monogram.prefix(3))).font(.system(size: 3.6, weight: .black)).foregroundColor(c(kit.primary)),
                         at: CGPoint(x: 67, y: 25.5))
        }

        // Shirt sponsor across the chest, in whichever colour reads best.
        if let sponsor, !sponsor.isEmpty {
            let backdrop = kit.pattern == .band || kit.pattern == .chevron ? kit.secondary : kit.primary
            let ink = KitColour.luminance(backdrop) > 0.55 ? Color.black : Color.white
            context.draw(Text(sponsor.uppercased()).font(.system(size: 9, weight: .heavy)).foregroundColor(ink),
                         at: CGPoint(x: 50, y: 50))
        }

        // Shorts
        var shorts = Path()
        shorts.addLines([CGPoint(x: 22, y: 104), CGPoint(x: 78, y: 104), CGPoint(x: 82, y: 136),
                         CGPoint(x: 54, y: 136), CGPoint(x: 50, y: 122), CGPoint(x: 46, y: 136), CGPoint(x: 18, y: 136)])
        shorts.closeSubpath()
        context.fill(shorts, with: .color(c(kit.shorts)))
        context.fill(Path(CGRect(x: 22, y: 104, width: 56, height: 3)), with: .color(c(kit.trim)))
        context.stroke(shorts, with: .color(outline), lineWidth: 1.2)

        // Socks
        for x in [24.0, 58.0] {
            let sock = Path(roundedRect: CGRect(x: x, y: 142, width: 18, height: 34), cornerRadius: 3)
            context.fill(sock, with: .color(c(kit.socks)))
            context.fill(Path(CGRect(x: x, y: 146, width: 18, height: 4)), with: .color(c(kit.trim)))
            context.stroke(sock, with: .color(outline), lineWidth: 1.0)
        }
    }
}

// MARK: - Shirt sponsor helper

extension GameState {
    /// The user club's main shirt sponsor (the most valuable deal), if any.
    public var shirtSponsorName: String? {
        guard let deal = owner.sponsorshipDeals.max(by: { $0.annualValue < $1.annualValue }) else { return nil }
        let name = deal.sponsorName.replacingOccurrences(of: " " + deal.tier.rawValue, with: "")
        return name.isEmpty ? nil : name
    }
}

// MARK: - Kit designer

public struct KitDesignerView: View {
    @Environment(GameState.self) private var gameState
    @Environment(\.dismiss) private var dismiss
    @State private var draft: KitDesign
    @State private var original: KitDesign
    private let clubId: UUID

    public init(club: Club) {
        clubId = club.id
        _draft = State(initialValue: club.effectiveKit)
        _original = State(initialValue: club.effectiveKit)
    }

    private var club: Club? { gameState.club(withId: clubId) }

    public var body: some View {
        NavigationStack {
            Form {
                if let club {
                    let tradition = club.traditionalKit
                    let approval = draft.approval(comparedTo: tradition)
                    let changed = draft != tradition
                    let currentMult = KitDesign.merchandiseMultiplier(approval: original.approval(comparedTo: tradition), changed: original != tradition)
                    let newMult = KitDesign.merchandiseMultiplier(approval: approval, changed: changed)
                    let projected = Int(Double(club.finances.merchandiseIncome) * newMult / currentMult)

                    Section {
                        HStack {
                            Spacer()
                            KitView(kit: draft, sponsor: gameState.shirtSponsorName, monogram: club.shortName, height: 240)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.surface)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Supporter approval").font(.subheadline).fontWeight(.semibold)
                                Spacer()
                                Text("\(Int(approval * 100))%").font(.subheadline).fontWeight(.heavy).monospacedDigit()
                            }
                            ProgressView(value: approval)
                                .tint(approval > 0.75 ? Color.winGreen : approval > 0.5 ? Color.highlight : Color.lossRed)
                            Text(KitDesign.verdict(for: approval)).font(.caption).foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Supporter approval \(Int(approval * 100)) percent. \(KitDesign.verdict(for: approval))")

                        LabeledContent("Merchandise income", value: "\(Player.formatCurrency(projected)) a year")
                            .accessibilityLabel("Projected merchandise income \(Player.spokenCurrency(projected)) a year, \(projected >= club.finances.merchandiseIncome ? "up" : "down") from \(Player.spokenCurrency(club.finances.merchandiseIncome))")
                        if gameState.shirtSponsorName == nil {
                            Text("Sign a commercial partner and their name will appear across the shirt.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Preview")
                    }

                    Section("Pattern") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(KitDesign.Pattern.allCases) { pattern in
                                    Button {
                                        Haptics.selection()
                                        draft.pattern = pattern
                                    } label: {
                                        VStack(spacing: 6) {
                                            KitView(kit: draft.with(pattern: pattern), height: 90)
                                            Text(pattern.rawValue).font(.caption2).fontWeight(.semibold)
                                        }
                                        .padding(8)
                                        .background(draft.pattern == pattern ? Color.brand.opacity(0.3) : Color.surfaceRaised)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(draft.pattern == pattern ? Color.brand : Color.clear, lineWidth: 2))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(pattern.rawValue)
                                    .accessibilityAddTraits(draft.pattern == pattern ? [.isSelected, .isButton] : .isButton)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    Section("Colours") {
                        colourRow("Main colour", \.primary)
                        colourRow("Pattern colour", \.secondary)
                        colourRow("Trim", \.trim)
                        colourRow("Shorts", \.shorts)
                        colourRow("Socks", \.socks)
                    }

                    Section("Details") {
                        Picker("Collar", selection: $draft.collar) {
                            ForEach(KitDesign.Collar.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Toggle("Contrast sleeves", isOn: $draft.contrastSleeves)
                    }

                    Section {
                        Button("Restore Traditional Kit") {
                            Haptics.tap()
                            draft = tradition
                        }
                        .disabled(draft == tradition)
                    } footer: {
                        Text("Supporters judge every change against the club's traditional colours. A popular new look sells shirts; an unpopular one hurts merchandise sales.")
                    }
                }
            }
            .navigationTitle("Kit Designer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Unveil") { save() }
                        .fontWeight(.bold)
                        .disabled(draft == original)
                        .accessibilityHint("Saves the new kit and announces it to supporters")
                }
            }
        }
        .touchlineChrome()
    }

    private func colourRow(_ title: String, _ key: WritableKeyPath<KitDesign, String>) -> some View {
        HStack {
            Menu {
                ForEach(KitColour.palette, id: \.0) { entry in
                    Button(entry.0) { Haptics.selection(); draft[keyPath: key] = entry.1 }
                }
            } label: {
                HStack {
                    Text(title).foregroundStyle(.primary)
                    Spacer()
                    Text(KitColour.name(draft[keyPath: key]).capitalized).foregroundStyle(.secondary)
                }
            }
            .accessibilityLabel("\(title), \(KitColour.name(draft[keyPath: key]))")
            .accessibilityHint("Choose from named colours")
            ColorPicker(title, selection: Binding(
                get: { Color(hex: draft[keyPath: key]) },
                set: { draft[keyPath: key] = KitColour.hex(from: $0) }
            ), supportsOpacity: false)
            .labelsHidden()
            .accessibilityLabel("Custom \(title.lowercased())")
        }
    }

    private func save() {
        guard let index = gameState.clubs.firstIndex(where: { $0.id == clubId }) else { return }
        let tradition = gameState.clubs[index].traditionalKit
        let oldMult = KitDesign.merchandiseMultiplier(approval: original.approval(comparedTo: tradition), changed: original != tradition)
        let approval = draft.approval(comparedTo: tradition)
        let newMult = KitDesign.merchandiseMultiplier(approval: approval, changed: draft != tradition)
        let merch = gameState.clubs[index].finances.merchandiseIncome
        gameState.clubs[index].finances.merchandiseIncome = Int(Double(merch) * newMult / oldMult)
        gameState.clubs[index].kit = draft == tradition ? nil : draft
        let clubName = gameState.clubs[index].name
        gameState.news.insert(NewsItem(
            headline: "\(clubName) unveil a new kit",
            body: "\(draft.spokenDescription) \(KitDesign.verdict(for: approval))",
            date: gameState.season.currentDate,
            category: .general
        ), at: 0)
        try? SaveManager.shared.autoSave(gameState: gameState)
        approval >= 0.55 ? Haptics.success() : Haptics.warning()
        dismiss()
    }
}
