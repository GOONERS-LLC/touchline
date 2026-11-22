//
//  TipCard.swift
//  Touchline
//
//  A dismissible getting-started tip.
//

import SwiftUI

struct TipCard: View {
    @Environment(GameState.self) private var gameState

    var body: some View {
        if let tip = gameState.nextTip {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: tip.icon).accessibilityHidden(true)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("TIP • " + tip.title.uppercased())
                        .font(.caption2.weight(.heavy))
                        .tracking(0.8)
                        .foregroundStyle(Color.accentColor)
                    Text(tip.body).font(.subheadline)
                    HStack {
                        Button("Got it") {
                            withAnimation(.snappy) { gameState.dismissTip(tip.id) }
                        }
                        .font(.subheadline.weight(.bold))
                        Spacer()
                        Button("Hide all tips") {
                            withAnimation(.snappy) { gameState.dismissAllTips() }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 2)
                }
            }
            .gfCard()
            .transition(.opacity.combined(with: .move(edge: .top)))
            .accessibilityElement(children: .contain)
        }
    }
}
