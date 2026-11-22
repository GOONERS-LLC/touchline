//
//  CareerHistoryCard.swift
//  Touchline
//
//  A player's career season by season, with a chart of how his rating has
//  developed. Keepers show clean sheets and goals conceded instead of goals
//  and assists.
//

import SwiftUI
import Charts

struct CareerHistoryCard: View {
    let log: [PlayerSeasonLine]
    var isKeeper: Bool = false

    private func primaryStat(_ line: PlayerSeasonLine) -> Int { isKeeper ? (line.cleanSheets ?? 0) : line.goals }
    private func secondaryStat(_ line: PlayerSeasonLine) -> Int { isKeeper ? (line.goalsConceded ?? 0) : line.assists }

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
                Text(isKeeper ? "CS" : "G").frame(width: 28, alignment: .trailing)
                Text(isKeeper ? "GA" : "A").frame(width: 28, alignment: .trailing)
                Text("Avg").frame(width: 38, alignment: .trailing)
            }
            .font(.caption2.weight(.heavy))
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
            ForEach(log.reversed()) { line in
                HStack {
                    Text(line.season).frame(maxWidth: .infinity, alignment: .leading)
                    Text(line.club).frame(width: 44, alignment: .leading)
                    Text("\(line.appearances)").frame(width: 38, alignment: .trailing)
                    Text("\(primaryStat(line))").frame(width: 28, alignment: .trailing)
                    Text("\(secondaryStat(line))").frame(width: 28, alignment: .trailing)
                    Text(line.appearances > 0 ? String(format: "%.1f", line.averageRating) : "–").frame(width: 38, alignment: .trailing)
                }
                .font(.caption.monospacedDigit())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(isKeeper
                    ? "\(line.season) at \(line.club): \(line.appearances) appearances, \(primaryStat(line)) clean sheets, \(secondaryStat(line)) goals conceded"
                    : "\(line.season) at \(line.club): \(line.appearances) appearances, \(line.goals) goals, \(line.assists) assists")
            }
            let totals = log.reduce((apps: 0, first: 0, second: 0)) { ($0.apps + $1.appearances, $0.first + primaryStat($1), $0.second + secondaryStat($1)) }
            Divider()
            HStack {
                Text("Total").fontWeight(.bold).frame(maxWidth: .infinity, alignment: .leading)
                Text("\(totals.apps)").frame(width: 38 + 44 + 8, alignment: .trailing)
                Text("\(totals.first)").frame(width: 28, alignment: .trailing)
                Text("\(totals.second)").frame(width: 28, alignment: .trailing)
                Text("").frame(width: 38)
            }
            .font(.caption.weight(.bold).monospacedDigit())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isKeeper
                ? "Career total: \(totals.apps) appearances, \(totals.first) clean sheets, \(totals.second) goals conceded"
                : "Career total: \(totals.apps) appearances, \(totals.first) goals, \(totals.second) assists")
        }
        .gfCard()
    }
}
