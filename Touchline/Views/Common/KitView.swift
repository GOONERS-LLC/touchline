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
                    .buttonStyle(.gfPrimary)
                }
            }
            .padding(.vertical, 6)
            .sheet(isPresented: $designing) {
                KitDesignerView(club: club).environment(gameState)
            }
        }
    }
}

/// A page holding the kit card, for the manager's home grid.
struct ClubKitPage: View {
    var body: some View {
        ScrollView {
            ClubKitCard()
                .gfCard()
                .padding()
        }
        .stadiumBackground()
        .navigationTitle("Club Kit")
        .navigationBarTitleDisplayMode(.inline)
    }
}
