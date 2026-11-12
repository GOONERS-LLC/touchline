//
//  Rivalry.swift
//  Touchline
//
//  Real derbies and rivalries (North London Derby, El Clásico, Old Firm...).
//  Derbies are fiercer and less predictable, draw bigger crowds, swing morale
//  and board confidence, and rival clubs refuse to do business with each other.
//

import Foundation

public struct Rivalry: Codable, Hashable {
    public let clubA: UUID
    public let clubB: UUID
    /// e.g. "North London Derby".
    public let name: String
    /// 1 (local rivalry) to 3 (fiercest derbies).
    public let intensity: Int

    public init(clubA: UUID, clubB: UUID, name: String, intensity: Int) {
        self.clubA = clubA
        self.clubB = clubB
        self.name = name
        self.intensity = max(1, min(3, intensity))
    }

    public func involves(_ a: UUID, _ b: UUID) -> Bool {
        (clubA == a && clubB == b) || (clubA == b && clubB == a)
    }
}

/// Lookup table for rivalries, keyed by an order-independent club pair.
public struct RivalryIndex {
    private var byPair: [String: Rivalry] = [:]

    public init(_ rivalries: [Rivalry]) {
        for rivalry in rivalries {
            let key = RivalryIndex.key(rivalry.clubA, rivalry.clubB)
            // Keep the fiercest entry if a pair is listed twice.
            if let existing = byPair[key], existing.intensity >= rivalry.intensity { continue }
            byPair[key] = rivalry
        }
    }

    public static func key(_ a: UUID, _ b: UUID) -> String {
        a.uuidString < b.uuidString ? a.uuidString + b.uuidString : b.uuidString + a.uuidString
    }

    public func rivalry(_ a: UUID, _ b: UUID) -> Rivalry? {
        byPair[RivalryIndex.key(a, b)]
    }
}

private struct RivalryFile: Codable {
    struct Entry: Codable {
        let clubA: String
        let clubB: String
        let name: String
        let intensity: Int
    }
    let rivalries: [Entry]
}

extension DataLoader {
    /// Loads the bundled rivalries and resolves club names to the given clubs.
    public static func loadRivalries(for clubs: [Club]) -> [Rivalry] {
        guard let url = Bundle.main.url(forResource: "rivalries", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(RivalryFile.self, from: data) else { return [] }
        var idByName: [String: UUID] = [:]
        for club in clubs where idByName[club.name] == nil {
            idByName[club.name] = club.id
        }
        return file.rivalries.compactMap { entry in
            guard let a = idByName[entry.clubA], let b = idByName[entry.clubB], a != b else { return nil }
            return Rivalry(clubA: a, clubB: b, name: entry.name, intensity: entry.intensity)
        }
    }
}
