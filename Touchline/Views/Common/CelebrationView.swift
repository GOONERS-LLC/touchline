//
//  CelebrationView.swift
//  Touchline
//
//  The cutscene for a title, a promotion, a cup or a European trophy: the
//  club's colours, the trophy lifted, confetti falling, the crowd roaring.
//

import SwiftUI

struct CelebrationView: View {
    @Environment(GameState.self) private var gameState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let celebration: Celebration

    @State private var lifted = false
    @State private var start = Date()

    private var club: Club? { gameState.club(withId: celebration.clubId) }

    private var symbol: String {
        switch celebration.kind {
        case .champions, .europe: return "trophy.fill"
        case .cup: return "trophy.circle.fill"
        case .promotion: return "arrow.up.circle.fill"
        }
    }

    var body: some View {
        let primary = Color(hex: club?.primaryColor ?? "#1F3A93")
        let secondary = Color(hex: club?.secondaryColor ?? "#FFFFFF")
        ZStack {
            LinearGradient(colors: [primary, Color.black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            if !reduceMotion {
                confetti(primary: primary, secondary: secondary)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            }
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: symbol)
                    .font(.system(size: 120))
                    .foregroundStyle(Color(hex: "FFD45C"))
                    .shadow(color: Color(hex: "FFD45C").opacity(0.8), radius: lifted ? 30 : 4)
                    .scaleEffect(lifted ? 1.0 : 0.3)
                    .rotationEffect(.degrees(lifted ? 0 : -25))
                    .offset(y: lifted ? 0 : 80)
                    .accessibilityHidden(true)
                Text(celebration.title)
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(lifted ? 1 : 0)
                    .scaleEffect(lifted ? 1 : 1.6)
                if let club {
                    HStack(spacing: 10) {
                        CrestView(club: club, size: 40)
                        Text(club.name.uppercased())
                            .font(.gfDisplay(22))
                            .foregroundStyle(.white)
                    }
                    .opacity(lifted ? 1 : 0)
                }
                Text(celebration.subtitle)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .opacity(lifted ? 1 : 0)
                Spacer()
                Button {
                    gameState.celebrationToShow = nil
                    try? SaveManager.shared.autoSave(gameState: gameState)
                } label: {
                    Text("Continue").font(.headline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.gfPrimary)
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            }
        }
        .accessibilityElement(children: .contain)
        .onAppear {
            start = Date()
            withAnimation(reduceMotion ? .none : .spring(response: 0.9, dampingFraction: 0.55).delay(0.2)) { lifted = true }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            CrowdAtmosphere.shared.resultVerdict(outcome: "W")
            AccessibilityNotification.Announcement("\(celebration.title) \(club?.name ?? ""). \(celebration.subtitle)").post()
        }
    }

    /// Falling paper in the club's colours and gold.
    private func confetti(primary: Color, secondary: Color) -> some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSince(start)
                let colours = [primary, secondary, Color(hex: "FFD45C"), .white]
                for i in 0..<90 {
                    let seed = Double(i)
                    let speed = 70 + (seed * 37).truncatingRemainder(dividingBy: 90)
                    let x0 = (seed * 97).truncatingRemainder(dividingBy: Double(size.width))
                    let sway = sin(t * 1.6 + seed) * 22
                    let y = ((t * speed) + seed * 41).truncatingRemainder(dividingBy: Double(size.height + 40)) - 20
                    let rect = CGRect(x: x0 + sway, y: y, width: 7, height: 12)
                    var piece = context
                    piece.translateBy(x: rect.midX, y: rect.midY)
                    piece.rotate(by: .radians(t * 3 + seed))
                    piece.fill(Path(CGRect(x: -3.5, y: -6, width: 7, height: 12)),
                               with: .color(colours[i % colours.count]))
                }
            }
        }
    }
}
