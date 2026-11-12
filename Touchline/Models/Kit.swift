//
//  Kit.swift
//  Touchline
//
//  A club's home kit: shirt pattern, colours, collar, shorts and socks.
//  Clubs start in their traditional colours (and, for famous designs, their
//  traditional pattern). Owners can redesign the kit; supporters react to how
//  far it strays from tradition, which moves merchandise income.
//

import Foundation
import SwiftUI

public struct KitDesign: Codable, Hashable {

    public enum Pattern: String, Codable, CaseIterable, Identifiable {
        case plain = "Plain"
        case stripes = "Stripes"
        case pinstripes = "Pinstripes"
        case hoops = "Hoops"
        case halves = "Halves"
        case quarters = "Quarters"
        case sash = "Sash"
        case centreStripe = "Centre Stripe"
        case chevron = "Chevron"
        case band = "Chest Band"

        public var id: String { rawValue }

        public var spoken: String {
            switch self {
            case .plain: return "plain"
            case .stripes: return "vertical stripes"
            case .pinstripes: return "thin pinstripes"
            case .hoops: return "horizontal hoops"
            case .halves: return "halves, split down the middle"
            case .quarters: return "quarters"
            case .sash: return "a diagonal sash"
            case .centreStripe: return "a broad centre stripe"
            case .chevron: return "a chevron across the chest"
            case .band: return "a band across the chest"
            }
        }
    }

    public enum Collar: String, Codable, CaseIterable, Identifiable {
        case crew = "Crew Neck"
        case vNeck = "V-Neck"
        case polo = "Polo Collar"
        public var id: String { rawValue }
    }

    public var pattern: Pattern
    public var primary: String
    public var secondary: String
    public var trim: String
    public var shorts: String
    public var socks: String
    public var collar: Collar
    public var contrastSleeves: Bool

    public init(pattern: Pattern, primary: String, secondary: String, trim: String,
                shorts: String, socks: String, collar: Collar = .crew, contrastSleeves: Bool = false) {
        self.pattern = pattern
        self.primary = primary
        self.secondary = secondary
        self.trim = trim
        self.shorts = shorts
        self.socks = socks
        self.collar = collar
        self.contrastSleeves = contrastSleeves
    }

    public func with(pattern: Pattern) -> KitDesign {
        var copy = self
        copy.pattern = pattern
        return copy
    }

    // MARK: - Traditional kits

    /// Famous patterns keyed by a distinctive part of the club name.
    private static let traditions: [(String, Pattern)] = [
        ("celtic", .hoops), ("queens park rangers", .hoops), ("sporting cp", .hoops), ("sporting clube", .hoops),
        ("flamengo", .hoops), ("boca juniors", .band), ("river plate", .sash), ("vasco", .sash),
        ("ajax", .centreStripe), ("feyenoord", .halves), ("blackburn", .halves), ("galatasaray", .halves),
        ("slavia", .halves), ("bristol rovers", .quarters),
        ("newcastle", .stripes), ("juventus", .stripes), ("barcelona", .stripes), ("inter", .stripes),
        ("atletico", .stripes), ("atlético", .stripes), ("athletic club", .stripes), ("sunderland", .stripes),
        ("brentford", .stripes), ("stoke", .stripes), ("sheffield united", .stripes), ("southampton", .stripes),
        ("porto", .stripes), ("brugge", .stripes), ("atalanta", .stripes), ("milan", .stripes),
        ("botafogo", .stripes), ("fluminense", .stripes), ("estudiantes", .stripes), ("racing club", .stripes),
        ("olympiakos", .stripes), ("olympiacos", .stripes), ("paok", .stripes), ("fenerbahce", .stripes),
        ("fenerbahçe", .stripes), ("partizan", .stripes), ("crvena", .stripes), ("red star", .stripes),
        ("brighton", .stripes), ("crystal palace", .stripes), ("lincoln", .stripes), ("exeter", .stripes),
        ("notts county", .stripes), ("grimsby", .stripes), ("bilbao", .stripes),
    ]

    public static func traditional(name: String, primary: String, secondary: String) -> KitDesign {
        let lower = name.lowercased()
        let pattern = traditions.first { lower.contains($0.0) }?.1 ?? .plain
        let lightShorts = KitColour.luminance(primary) < 0.35
        return KitDesign(
            pattern: pattern,
            primary: primary,
            secondary: secondary,
            trim: secondary,
            shorts: pattern == .plain ? (lightShorts ? "#FFFFFF" : secondary) : (lightShorts ? primary : "#FFFFFF"),
            socks: primary,
            collar: name.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 3 == 0 ? .vNeck : .crew,
            contrastSleeves: false
        )
    }

    // MARK: - Description

    public var spokenDescription: String {
        let p = KitColour.name(primary), s = KitColour.name(secondary)
        let shirt = pattern == .plain
            ? "A plain \(p) shirt"
            : "A \(p) shirt with \(s) \(pattern.spoken)"
        let sleeves = contrastSleeves ? ", \(s) sleeves" : ""
        return "\(shirt)\(sleeves), \(collar.rawValue.lowercased()) trimmed in \(KitColour.name(trim)), \(KitColour.name(shorts)) shorts and \(KitColour.name(socks)) socks."
    }

    // MARK: - Supporters' reaction

    /// 0...1: how close a design stays to the club's traditional kit.
    public func approval(comparedTo tradition: KitDesign) -> Double {
        var score = 1.0
        score -= KitColour.distance(primary, tradition.primary) * 0.45
        score -= min(KitColour.distance(secondary, tradition.secondary), KitColour.distance(secondary, tradition.primary)) * 0.2
        score -= KitColour.distance(shorts, tradition.shorts) * 0.1
        score -= KitColour.distance(socks, tradition.socks) * 0.05
        if pattern != tradition.pattern { score -= tradition.pattern == .plain ? 0.08 : 0.2 }
        return max(0, min(1, score))
    }

    /// Supporters' verdict in words.
    public static func verdict(for approval: Double) -> String {
        switch approval {
        case 0.9...: return "Supporters love it. It looks like home."
        case 0.75..<0.9: return "A fresh take that most fans are happy with."
        case 0.55..<0.75: return "Fans are divided. Some like the change, many miss the old look."
        case 0.35..<0.55: return "Plenty of grumbling on the forums about abandoning tradition."
        default: return "Supporters are furious. Petitions are circulating to bring back the old kit."
        }
    }

    /// Merchandise multiplier: a modest novelty bonus for a new look the fans
    /// accept, and falling sales for one they reject.
    public static func merchandiseMultiplier(approval: Double, changed: Bool) -> Double {
        guard changed else { return 1.0 }
        return 0.75 + approval * 0.4   // 0.75 (hated) ... 1.15 (loved and new)
    }
}

/// Colour helpers for kits: names for VoiceOver and simple distances.
public enum KitColour {
    public static let palette: [(String, String)] = [
        ("White", "#FFFFFF"), ("Black", "#111111"), ("Red", "#D71920"), ("Claret", "#7A263A"),
        ("Maroon", "#5C0F1B"), ("Orange", "#F26A21"), ("Amber", "#FFB020"), ("Yellow", "#FDE100"),
        ("Gold", "#C8A24A"), ("Green", "#00843D"), ("Dark Green", "#0B4D2C"), ("Lime", "#8DC63F"),
        ("Sky Blue", "#6CABDD"), ("Royal Blue", "#0047AB"), ("Navy", "#14213D"), ("Teal", "#00857C"),
        ("Purple", "#5B2D90"), ("Pink", "#F49AC1"), ("Grey", "#8A8D91"), ("Silver", "#C7CED6"),
    ]

    static func rgb(_ hex: String) -> (Double, Double, Double) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var v: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&v)
        if clean.count == 3 {
            return (Double((v >> 8) & 0xF) / 15, Double((v >> 4) & 0xF) / 15, Double(v & 0xF) / 15)
        }
        return (Double((v >> 16) & 0xFF) / 255, Double((v >> 8) & 0xFF) / 255, Double(v & 0xFF) / 255)
    }

    public static func luminance(_ hex: String) -> Double {
        let (r, g, b) = rgb(hex)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// 0 (identical) ... 1 (opposite).
    public static func distance(_ a: String, _ b: String) -> Double {
        let x = rgb(a), y = rgb(b)
        let d = sqrt(pow(x.0 - y.0, 2) * 0.3 + pow(x.1 - y.1, 2) * 0.59 + pow(x.2 - y.2, 2) * 0.11)
        return min(1, d * 1.3)
    }

    /// Nearest named colour, so VoiceOver says "claret" rather than a hex code.
    public static func name(_ hex: String) -> String {
        palette.min { distance(hex, $0.1) < distance(hex, $1.1) }?.0.lowercased() ?? "coloured"
    }

    /// Hex string from a SwiftUI colour (used by the colour pickers).
    public static func hex(from color: Color) -> String {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(max(0, min(1, r)) * 255), Int(max(0, min(1, g)) * 255), Int(max(0, min(1, b)) * 255))
    }
}

extension Club {
    /// The kit as the club currently wears it.
    public var effectiveKit: KitDesign {
        kit ?? traditionalKit
    }

    /// The club's traditional kit, the yardstick supporters judge changes by.
    public var traditionalKit: KitDesign {
        KitDesign.traditional(name: name, primary: primaryColor, secondary: secondaryColor)
    }
}
