//
//  MomentumChartView.swift
//  Touchline
//
//  Match momentum after the final whistle: for each five-minute spell, how
//  much pressure each side applied (goals, shots, chances, corners), drawn as
//  bars above the line for the home side and below it for the away side,
//  with goals marked.
//

import SwiftUI
import Charts

struct MomentumChartView: View {
    let result: MatchResult
    let homeName: String
    let awayName: String
    let homeColor: Color
    let awayColor: Color

    private struct Spell: Identifiable {
        let id: Int          // starting minute of the five-minute spell
        let pressure: Double // positive = home on top, negative = away
    }

    private struct GoalMark: Identifiable {
        let id = UUID()
        let minute: Int
        let isHome: Bool
    }

    private static func weight(_ type: MatchEventType) -> Double {
        switch type {
        case .goal, .penalty: return 3
        case .shotOnTarget, .woodwork: return 1.6
        case .chance, .chanceMissed, .penaltyMissed: return 1
        case .corner, .freeKick: return 0.5
        default: return 0
        }
    }

    private var spells: [Spell] {
        let lastMinute = max(90, result.events.map { $0.minute }.max() ?? 90)
        var buckets = [Double](repeating: 0, count: lastMinute / 5 + 1)
        for event in result.events {
            let w = Self.weight(event.type)
            guard w > 0 else { continue }
            let idx = min(buckets.count - 1, max(0, event.minute / 5))
            buckets[idx] += event.isHomeTeam ? w : -w
        }
        // A light rolling average so the chart reads as momentum, not noise.
        return buckets.indices.map { i in
            let window = buckets[max(0, i - 1)...min(buckets.count - 1, i + 1)]
            let avg = (buckets[i] * 2 + window.reduce(0, +) - buckets[i]) / Double(window.count + 1)
            return Spell(id: i * 5, pressure: avg)
        }
    }

    private var goals: [GoalMark] {
        result.events.filter { $0.type == .goal || $0.type == .ownGoal }
            .map { GoalMark(minute: $0.minute, isHome: $0.isHomeTeam) }
    }

    var body: some View {
        let data = spells
        let peak = max(1, data.map { abs($0.pressure) }.max() ?? 1)
        VStack(alignment: .leading, spacing: 8) {
            Text("Match Momentum").font(.headline)
            Chart {
                ForEach(data) { spell in
                    BarMark(
                        x: .value("Minute", spell.id),
                        y: .value("Pressure", spell.pressure),
                        width: .fixed(9)
                    )
                    .foregroundStyle(spell.pressure >= 0 ? homeColor : awayColor)
                    .cornerRadius(2)
                }
                RuleMark(y: .value("Even", 0))
                    .foregroundStyle(.secondary.opacity(0.5))
                ForEach(goals) { goal in
                    PointMark(
                        x: .value("Minute", goal.minute),
                        y: .value("Pressure", goal.isHome ? peak * 1.15 : -peak * 1.15)
                    )
                    .symbol {
                        Image(systemName: "soccerball")
                            .font(.caption2)
                    }
                }
                RuleMark(x: .value("Half-time", 45))
                    .foregroundStyle(.secondary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
            .chartYScale(domain: -peak * 1.3 ... peak * 1.3)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: [0, 15, 30, 45, 60, 75, 90]) { value in
                    AxisGridLine()
                    AxisValueLabel { if let m = value.as(Int.self) { Text("\(m)'") } }
                }
            }
            .frame(height: 140)
            HStack {
                Label(homeName, systemImage: "arrow.up").foregroundStyle(homeColor)
                Spacer()
                Label(awayName, systemImage: "arrow.down").foregroundStyle(awayColor)
            }
            .font(.caption.weight(.semibold))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary(data))
    }

    private func accessibilitySummary(_ data: [Spell]) -> String {
        let homeSpells = data.filter { $0.pressure > 0.5 }.count
        let awaySpells = data.filter { $0.pressure < -0.5 }.count
        return "Match momentum: \(homeName) on top for \(homeSpells) five-minute spells, \(awayName) for \(awaySpells)."
    }
}
