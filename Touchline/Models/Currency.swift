//
//  Currency.swift
//  Touchline
//
//  Money is shown in the currency of the country the user's club plays in:
//  pounds in England and Scotland, euros across the eurozone, dollars in
//  the United States, and so on. The game keeps every amount in pounds
//  internally; only the display converts.
//

import Foundation

public struct Currency: Equatable {
    public let symbol: String
    /// Spoken name, plural: "pounds", "euros".
    public let name: String
    /// Units of this currency per pound.
    public let rate: Double

    public static let pound = Currency(symbol: "£", name: "pounds", rate: 1)
    public static let euro = Currency(symbol: "€", name: "euros", rate: 1.17)

    /// The currency on screen now (set from the user's club each time the
    /// interface is drawn).
    public static var active: Currency = .pound

    public static func of(_ country: LeagueCountry) -> Currency {
        switch country {
        case .england, .scotland: return .pound
        case .spain, .italy, .germany, .france, .portugal, .netherlands, .belgium, .austria, .croatia, .greece:
            return .euro
        case .unitedStates: return Currency(symbol: "$", name: "dollars", rate: 1.27)
        case .mexico: return Currency(symbol: "MX$", name: "Mexican pesos", rate: 23)
        case .switzerland: return Currency(symbol: "CHF ", name: "Swiss francs", rate: 1.12)
        case .turkey: return Currency(symbol: "₺", name: "lira", rate: 42)
        case .denmark: return Currency(symbol: "DKK ", name: "Danish kroner", rate: 8.7)
        case .norway: return Currency(symbol: "NOK ", name: "Norwegian kroner", rate: 13.6)
        case .sweden: return Currency(symbol: "SEK ", name: "Swedish kronor", rate: 13.5)
        case .poland: return Currency(symbol: "zł ", name: "złoty", rate: 5.0)
        case .czechRepublic: return Currency(symbol: "Kč ", name: "koruna", rate: 29)
        case .romania: return Currency(symbol: "lei ", name: "lei", rate: 5.8)
        case .serbia: return Currency(symbol: "RSD ", name: "dinars", rate: 137)
        case .ukraine: return Currency(symbol: "₴", name: "hryvnias", rate: 52)
        case .russia: return Currency(symbol: "₽", name: "roubles", rate: 115)
        default: return .pound
        }
    }

    /// Updates the active currency for the user's club's country.
    @discardableResult
    public static func update(for country: LeagueCountry?) -> Bool {
        let next = country.map(of) ?? .pound
        if next != active { active = next }
        return true
    }
}
