//
//  FeedbackSettingsSection.swift
//  Touchline
//
//  Settings for haptics, crowd atmosphere and how live commentary is read.
//  Stored per device, so they apply to every career and save slot.
//

import SwiftUI

struct FeedbackSettingsSection: View {
    @AppStorage(PrefKey.haptics) private var haptics = true
    @AppStorage(PrefKey.crowd) private var crowd = true
    @AppStorage(PrefKey.crowdVolume) private var crowdVolume = 0.7
    @AppStorage(PrefKey.commentaryDetail) private var detailRaw = CommentaryDetail.everything.rawValue
    @AppStorage(PrefKey.waitForVoiceOver) private var waitForVoiceOver = true
    @AppStorage(PrefKey.announceScore) private var announceScore = true
    @AppStorage(PrefKey.minuteUpdates) private var minuteUpdates = true

    var body: some View {
        Section {
            Toggle(isOn: $haptics) {
                settingLabel("Haptics", "Vibrations for goals, cards, saves, the woodwork and button presses.", "iphone.radiowaves.left.and.right")
            }
            .onChange(of: haptics) { _, on in if on { Haptics.success() } }

            Toggle(isOn: $crowd) {
                settingLabel("Crowd Atmosphere", "A live crowd that roars, groans, boos and applauds as the match unfolds.", "person.3.sequence.fill")
            }

            if crowd {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Crowd Volume")
                    Slider(value: $crowdVolume, in: 0.1...1, step: 0.1) {
                        Text("Crowd Volume")
                    } minimumValueLabel: {
                        Image(systemName: "speaker.fill").accessibilityHidden(true)
                    } maximumValueLabel: {
                        Image(systemName: "speaker.wave.3.fill").accessibilityHidden(true)
                    }
                    .accessibilityValue("\(Int(crowdVolume * 100)) percent")
                }
            }
        } header: {
            Text("Feedback")
        }

        Section {
            Picker(selection: $detailRaw) {
                ForEach(CommentaryDetail.allCases) { level in
                    Text(level.rawValue).tag(level.rawValue)
                }
            } label: {
                settingLabel("Commentary Detail", (CommentaryDetail(rawValue: detailRaw) ?? .everything).description, "text.bubble.fill")
            }

            Toggle(isOn: $waitForVoiceOver) {
                settingLabel("Wait for VoiceOver", "Holds the match clock until VoiceOver has finished reading each line, so you never miss a moment.", "hourglass")
            }

            Toggle(isOn: $announceScore) {
                settingLabel("Read the Score After Goals", "After every goal, VoiceOver reads the updated score.", "number.circle.fill")
            }

            Toggle(isOn: $minuteUpdates) {
                settingLabel("Quarter-Hour Updates", "Every fifteen minutes, VoiceOver reads the time and the score.", "clock.fill")
            }
        } header: {
            Text("Live Match Accessibility")
        } footer: {
            Text("Slow the replay itself with Replay Speed under Match Playback. Very Slow gives around a minute and a half for every half of football.")
        }
    }

    private func settingLabel(_ title: String, _ detail: String, _ icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.highlight)
                .frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
