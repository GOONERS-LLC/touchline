//
//  CrowdAtmosphere.swift
//  Touchline
//
//  Real stadium crowd sound for live matches, built from recordings released
//  into the public domain (CC0) on Freesound; see Sounds/CREDITS.md. A crowd
//  bed loops under the match, chosen by the size of the home stadium, and the
//  home supporters react to what happens: a roar for a home goal, a groan for
//  an away goal, an "ooh" for the woodwork, boos for bookings against them,
//  applause for a save, and singing when their side is on top.
//

import AVFoundation
import Foundation

public final class CrowdAtmosphere {
    public static let shared = CrowdAtmosphere()

    enum Clip: String {
        case bedSmall = "crowd_bed_small"
        case bedMedium = "crowd_bed_medium"
        case bedLarge = "crowd_bed_large"
        case goal1 = "crowd_goal_1"
        case goal2 = "crowd_goal_2"
        case goal3 = "crowd_goal_3"
        case ooh1 = "crowd_ooh_1"
        case ooh2 = "crowd_ooh_2"
        case groan = "crowd_groan"
        case boo = "crowd_boo"
        case cheer = "crowd_cheer"
        case applause = "crowd_applause"
        case chant = "crowd_chant"
        case whistle = "referee_whistle"
    }

    /// Settings keys (Settings, Crowd Sound).
    public static let enabledKey = "tlCrowdSoundEnabled"
    public static let volumeKey = "tlCrowdVolume"

    private var bed: AVAudioPlayer?
    private var reactions: [AVAudioPlayer] = []
    private var cache: [Clip: Data] = [:]
    private var intensity: Float = 0.4
    private var lastChant = Date.distantPast

    private init() {
        UserDefaults.standard.register(defaults: [Self.enabledKey: true, Self.volumeKey: 0.8])
    }

    private var enabled: Bool { UserDefaults.standard.bool(forKey: Self.enabledKey) }
    private var masterVolume: Float { Float(UserDefaults.standard.double(forKey: Self.volumeKey)) }

    private func data(_ clip: Clip) -> Data? {
        if let d = cache[clip] { return d }
        guard let url = Bundle.main.url(forResource: clip.rawValue, withExtension: "m4a"),
              let d = try? Data(contentsOf: url) else { return nil }
        cache[clip] = d
        return d
    }

    private func player(_ clip: Clip) -> AVAudioPlayer? {
        guard let d = data(clip), let p = try? AVAudioPlayer(data: d) else { return nil }
        p.prepareToPlay()
        return p
    }

    // MARK: - Match control

    /// Starts the crowd for a match at a stadium of the given size.
    public func startMatch(capacity: Int) {
        stopMatch()
        guard enabled else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        let clip: Clip = capacity >= 50_000 ? .bedLarge : capacity >= 18_000 ? .bedMedium : .bedSmall
        guard let p = player(clip) else { return }
        p.numberOfLoops = -1
        intensity = 0.4
        p.volume = 0
        p.play()
        p.setVolume(bedVolume, fadeDuration: 1.5)
        bed = p
        play(.whistle, volume: 0.9)
    }

    public func pause() { bed?.pause(); reactions.forEach { $0.pause() } }
    public func resume() { if enabled { bed?.play() } }

    public func stopMatch() {
        bed?.setVolume(0, fadeDuration: 0.6)
        let old = bed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { old?.stop() }
        bed = nil
        reactions.forEach { $0.stop() }
        reactions.removeAll()
    }

    /// The full-time whistle, then the crowd fades. The verdict on the result
    /// is played by the full-time screen, for live and simulated matches alike.
    public func fullTime() {
        play(.whistle, volume: 1)
        let bed = self.bed
        bed?.setVolume(0, fadeDuration: 3)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) { bed?.stop() }
        self.bed = nil
    }

    /// The supporters' verdict on your result: a roar for a win, boos for a
    /// defeat, polite applause for a draw. Works without a live crowd running,
    /// so simulated matches get it too.
    public func resultVerdict(outcome: String) {
        guard enabled else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        switch outcome {
        case "W":
            play([.goal1, .goal3].randomElement()!, volume: 0.9, delay: 0.3)
            play(.applause, volume: 0.7, delay: 3.5)
        case "L":
            play(.boo, volume: 1, delay: 0.3)
        default:
            play(.applause, volume: 0.6, delay: 0.3)
        }
    }

    /// Lets the crowd settle between incidents.
    public func tickMinute(homeLeading: Bool) {
        intensity = max(0.3, intensity * 0.94)
        bed?.setVolume(bedVolume, fadeDuration: 0.4)
        if homeLeading, Date().timeIntervalSince(lastChant) > 40, Int.random(in: 0..<10) == 0 {
            lastChant = Date()
            play(.chant, volume: 0.65)
        }
    }

    private var bedVolume: Float { min(1, (0.35 + intensity * 0.6) * masterVolume) }

    private func lift(_ amount: Float) {
        intensity = min(1, max(0.25, intensity + amount))
        bed?.setVolume(bedVolume, fadeDuration: 0.3)
    }

    /// How the home crowd reacts to an event.
    public func react(to event: MatchEvent) {
        guard enabled, bed != nil else { return }
        let home = event.isHomeTeam
        switch event.type {
        case .goal, .penalty:
            if home {
                play([.goal1, .goal2, .goal3].randomElement()!, volume: 1)
                lift(0.6)
            } else {
                play(.groan, volume: 1)
                lift(-0.2)
            }
        case .ownGoal:
            // Credited to the side that benefits.
            play(home ? .groan : .goal1, volume: 1)
            lift(home ? -0.2 : 0.6)
        case .woodwork:
            play([.ooh1, .ooh2].randomElement()!, volume: 1)
            lift(0.3)
        case .chance, .chanceMissed:
            if home { play([.ooh1, .ooh2].randomElement()!, volume: 0.75); lift(0.15) }
        case .shotOnTarget:
            // The keeper saves: the home end groans or applauds its keeper.
            play(home ? .ooh1 : .applause, volume: 0.8)
            lift(0.2)
        case .yellowCard:
            play(home ? .boo : .cheer, volume: home ? 0.85 : 0.5)
            lift(0.1)
        case .redCard, .secondYellow:
            play(home ? .boo : .cheer, volume: 1)
            lift(0.3)
        case .penaltyMissed:
            play(home ? .groan : .cheer, volume: 1)
            lift(0.3)
        case .injury:
            play(.applause, volume: 0.45)
        case .substitution:
            if home { play(.applause, volume: 0.4) }
        case .halfTime:
            play(.whistle, volume: 1)
            play(.applause, volume: 0.6, delay: 0.7)
        case .kickOff:
            play(.whistle, volume: 0.9)
        default:
            break
        }
    }

    private func play(_ clip: Clip, volume: Float, delay: TimeInterval = 0) {
        guard enabled else { return }
        let work = { [weak self] in
            guard let self, let p = self.player(clip) else { return }
            p.volume = min(1, volume * self.masterVolume)
            p.play()
            self.reactions.append(p)
            self.reactions.removeAll { !$0.isPlaying && $0 !== p }
        }
        if delay > 0 { DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work) } else { work() }
    }
}
