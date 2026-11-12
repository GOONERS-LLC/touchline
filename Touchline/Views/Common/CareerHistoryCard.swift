//
//  CareerHistoryCard.swift
//  Touchline
//
//  A player's career season by season, with a chart of how his rating has
//  developed.
//

import SwiftUI
import Charts

struct CareerHistoryCard: View {
    let log: [PlayerSeasonLine]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GFSectionHeader(title: "Career", icon: "chart.line.uptrend.xyaxis")
            if log.count >= 2 {
                Chart(log) { line in
                    LineMark(x: .value("Season", line.season), y: .value("Rating", line.overall))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.accentColor)
                    PointMark(x: .value("Season", line.season), y: .value("Rating", line.overall))
                        .foregroundStyle(Color.accentColor)
                        .annotation(position: .top) {
                            Text("\(line.overall)").font(.caption2.weight(.bold))
                        }
                }
                .chartYScale(domain: max(0, (log.map { $0.overall }.min() ?? 50) - 5)...min(99, (log.map { $0.overall }.max() ?? 90) + 5))
                .frame(height: 130)
                .accessibilityLabel("Rating by season: " + log.map { "\($0.season) \($0.overall)" }.joined(separator: ", "))
            }
            HStack {
                Text("Season").frame(maxWidth: .infinity, alignment: .leading)
                Text("Club").frame(width: 44, alignment: .leading)
                Text("Apps").frame(width: 38, alignment: .trailing)
                Text("G").frame(width: 28, alignment: .trailing)
                Text("A").frame(width: 28, alignment: .trailing)
                Text("Avg").frame(width: 38, alignment: .trailing)
            }
            .font(.caption2.weight(.heavy))
            .foregroundStyle(.secondary)
            ForEach(log.reversed()) { line in
                HStack {
                    Text(line.season).frame(maxWidth: .infinity, alignment: .leading)
                    Text(line.club).frame(width: 44, alignment: .leading)
                    Text("\(line.appearances)").frame(width: 38, alignment: .trailing)
                    Text("\(line.goals)").frame(width: 28, alignment: .trailing)
                    Text("\(line.assists)").frame(width: 28, alignment: .trailing)
                    Text(line.appearances > 0 ? String(format: "%.1f", line.averageRating) : "–").frame(width: 38, alignment: .trailing)
                }
                .font(.caption.monospacedDigit())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(line.season) at \(line.club): \(line.appearances) appearances, \(line.goals) goals, \(line.assists) assists")
            }
            let totals = log.reduce((apps: 0, goals: 0, assists: 0)) { ($0.apps + $1.appearances, $0.goals + $1.goals, $0.assists + $1.assists) }
            Divider()
            HStack {
                Text("Total").fontWeight(.bold).frame(maxWidth: .infinity, alignment: .leading)
                Text("\(totals.apps)").frame(width: 38 + 44 + 8, alignment: .trailing)
                Text("\(totals.goals)").frame(width: 28, alignment: .trailing)
                Text("\(totals.assists)").frame(width: 28, alignment: .trailing)
                Text("").frame(width: 38)
            }
            .font(.caption.weight(.bold).monospacedDigit())
        }
        .gfCard()
    }
}
