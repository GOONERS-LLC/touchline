//
//  TouchlineStyle.swift
//  Touchline
//
//  The Touchline "Floodlight" palette and shared button styles.
//

import SwiftUI

extension Color {
    /// Brand colours
    public static let brand = Color(hex: "2F5BEA")          // Cobalt
    public static let brandDeep = Color(hex: "1D3BA8")
    public static let highlight = Color(hex: "FFB020")      // Floodlight amber

    /// Surfaces
    public static let ink = Color(hex: "0A0F1E")            // App background
    public static let surface = Color(hex: "121A2F")        // Cards
    public static let surfaceRaised = Color(hex: "1A2440")  // Raised cards, chips
    public static let hairline = Color(hex: "2B3760")       // Borders

}

/// Large primary call-to-action used for Continue, Play Match and similar.
public struct PrimaryActionStyle: ButtonStyle {
    public var tint: Color = .brand
    public init(tint: Color = .brand) { self.tint = tint }
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white)
            .background(
                LinearGradient(colors: [tint, tint.opacity(0.78)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in if pressed { Haptics.tap() } }
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Quiet secondary action that sits under a primary button.
public struct SecondaryActionStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .foregroundStyle(Color.primary)
            .background(Color.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.hairline, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in if pressed { Haptics.selection() } }
    }
}

/// Small uppercase section label used above cards.
public struct SectionEyebrow: View {
    let text: String
    public init(_ text: String) { self.text = text }
    public var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.heavy)
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(Color.highlight)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    /// Applies the Touchline look to an entire screen hierarchy.
    public func touchlineChrome() -> some View {
        self
            .tint(Color.brand)
            .preferredColorScheme(.dark)
            .scrollContentBackground(.hidden)
            .background(Color.ink.ignoresSafeArea())
    }
}
