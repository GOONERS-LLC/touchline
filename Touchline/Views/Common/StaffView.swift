//
//  StaffView.swift
//  Touchline
//
//  The backroom team, one card per member of staff: portrait, role, star
//  rating, wage and what they do. The manager can hire better people
//  (paid from club funds) or let someone go.
//

import SwiftUI

struct StaffView: View {
    @Environment(GameState.self) private var gameState
    @State private var group: StaffGroup = .coaching
    @State private var message: String?
    @State private var releasing: StaffMember?

    enum StaffGroup: String, CaseIterable { case coaching = "Coaching", scouting = "Scouting", medical = "Medical & Youth" }

    private func roles(_ g: StaffGroup) -> [StaffRole] {
        switch g {
        case .coaching: return [.assistantManager, .coach]
        case .scouting: return [.scout]
        case .medical: return [.physio, .youthCoach]
        }
    }

    var body: some View {
        ScrollView {
            if let club = gameState.userClub {
                VStack(spacing: 16) {
                    GFScreenTitle(title: "Staff", subtitle: "Club funds \(Player.formatCurrency(club.finances.balance))")
                    GFTabs(selection: $group)
                    ForEach(roles(group), id: \.self) { role in
                        let team = club.staff.filter { $0.role == role }
                        Text(role.displayName.uppercased())
                            .font(.gfLabel(16))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityAddTraits(.isHeader)
                        if team.isEmpty {
                            Text("Vacant. \(role.roleDescription)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .gfCard()
                        }
                        ForEach(team) { member in
                            staffCard(member)
                        }
                        hireMenu(role)
                    }
                }
                .padding()
            }
        }
        .stadiumBackground()
        .navigationTitle("Staff")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { gameState.currentScreen = .dashboard }
            }
        }
        .alert("Staff", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(message ?? "") }
        .confirmationDialog("Release \(releasing?.name ?? "")?",
                            isPresented: Binding(get: { releasing != nil }, set: { if !$0 { releasing = nil } }),
                            titleVisibility: .visible) {
            Button("Release", role: .destructive) {
                if let member = releasing, let idx = gameState.clubs.firstIndex(where: { $0.isUserClub }) {
                    gameState.clubs[idx].releaseStaff(withId: member.id)
                    message = "\(member.name) has left the club."
                    try? SaveManager.shared.autoSave(gameState: gameState)
                }
                releasing = nil
            }
            Button("Cancel", role: .cancel) { releasing = nil }
        }
    }

    private func staffCard(_ member: StaffMember) -> some View {
        let parts = member.name.split(separator: " ")
        let seed = ManagerProfile.generateSeed(first: String(parts.first ?? ""), last: String(parts.dropFirst().joined(separator: " ")))
        return VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                FaceView(seed: seed, size: 52, style: .full)
                    .frame(width: 52, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(alignment: .bottom) {
                        Text("\(member.quality) of 5")
                            .font(.gfLabel(12))
                            .foregroundStyle(Color.gfNight)
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Capsule().fill(Color.white))
                            .offset(y: 8)
                    }
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.name.uppercased()).font(.gfDisplay(16)).lineLimit(1).minimumScaleFactor(0.7)
                    Text(member.role.displayName).font(.subheadline.weight(.semibold))
                    HStack(spacing: 4) {
                        Text("SALARY").font(.gfLabel(12)).foregroundStyle(.secondary)
                        Text("\(Player.formatCurrency(member.wage))/w").font(.gfLabel(13))
                    }
                    Text(member.role.roleDescription).font(.caption).foregroundStyle(.secondary).lineLimit(3)
                }
                Spacer(minLength: 0)
            }
            Button("Release") { releasing = member }
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
        }
        .gfCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(member.name), \(member.role.displayName), \(member.quality) stars, \(Player.spokenCurrency(member.wage)) a week")
    }

    private func hireMenu(_ role: StaffRole) -> some View {
        NavigationLink {
            StaffMarketView(role: role)
        } label: {
            Text("Find \(role.displayName)")
                .font(.gfLabel(13))
                .textCase(.uppercase)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .foregroundStyle(Color.gfNight)
                .background(Capsule().fill(Color.white))
        }
        .accessibilityHint("Shows this month's candidates. The fee comes out of club funds.")
    }

    private func hire(_ role: StaffRole, stars: Int) {
        guard let idx = gameState.clubs.firstIndex(where: { $0.isUserClub }) else { return }
        if let staffer = gameState.clubs[idx].hireStaff(role: role, quality: stars) {
            message = "\(staffer.name) joins as \(role.displayName)."
            try? SaveManager.shared.autoSave(gameState: gameState)
        } else {
            message = "The club cannot afford that appointment."
        }
    }
}
