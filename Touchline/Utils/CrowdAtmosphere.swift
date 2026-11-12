//
//  CrowdAtmosphere.swift
//  Touchline
//
//  A synthesised stadium crowd for live matches. Everything is generated on
//  the device at launch (filtered noise shaped into murmurs, roars, groans and
//  claps), so there are no audio files to ship. The crowd follows the home
//  side: a home goal brings a roar, an away goal a deflated groan with the
//  travelling fans celebrating in the distance, fouls by the visitors are
//  booed, saves are applauded and near misses draw an "ooh".
//

import AVFoundation
import Foundation

public final class CrowdAtmosphere {
    public static let shared = CrowdAtmosphere()

    public enum Reaction: CaseIterable {
        case roar, awayRoar, groan, ooh, boo, applause, gasp, chant, whistleOfDerision, cheer
    }

    private let engine = AVAudioEngine()
    private let bedNode = AVAudioPlayerNode()
    private let reactionNodes = (0..<3).map { _ in AVAudioPlayerNode() }
    private var nextReactionNode = 0
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
    private var bed: AVAudioPCMBuffer?
    private var reactions: [Reaction: AVAudioPCMBuffer] = [:]
    private var isPrepared = false
    private var isRunning = false
    private let queue = DispatchQueue(label: "com.goonersllc.touchline.crowd", qos: .userInitiated)

    /// 0...1 match intensity. Raised by chances and goals, decays over time.
    private var intensity: Float = 0.35

    private init() {
        engine.attach(bedNode)
        engine.connect(bedNode, to: engine.mainMixerNode, format: format)
        for node in reactionNodes {
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
        }
    }

    /// Generates every sound in the background. Safe to call repeatedly.
    public func prepare() {
        queue.async { [self] in
            guard !isPrepared else { return }
            bed = makeBed(seconds: 8)
            reactions[.roar] = makeSwell(seconds: 5.5, attack: 0.25, peak: 1.0, centre: 900, voice: true, seed: 1)
            reactions[.awayRoar] = makeSwell(seconds: 3.5, attack: 0.3, peak: 0.35, centre: 1300, voice: true, seed: 2)
            reactions[.groan] = makeGroan(seconds: 2.6)
            reactions[.ooh] = makeOoh(seconds: 2.2)
            reactions[.boo] = makeBoo(seconds: 2.8)
            reactions[.applause] = makeApplause(seconds: 3.0, density: 1.0)
            reactions[.cheer] = makeSwell(seconds: 2.4, attack: 0.15, peak: 0.55, centre: 1100, voice: true, seed: 3)
            reactions[.gasp] = makeSwell(seconds: 1.4, attack: 0.05, peak: 0.6, centre: 1600, voice: false, seed: 4)
            reactions[.chant] = makeChant(seconds: 5.0)
            reactions[.whistleOfDerision] = makeWhistles(seconds: 2.4)
            isPrepared = true
        }
    }

    // MARK: - Match Control

    public func startMatch() {
        guard Preferences.crowdEnabled else { return }
        prepare()
        queue.async { [self] in
            guard isPrepared, !isRunning, let bed else { return }
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
                try AVAudioSession.sharedInstance().setActive(true)
                engine.mainMixerNode.outputVolume = Preferences.crowdVolume
                try engine.start()
                bedNode.scheduleBuffer(bed, at: nil, options: .loops)
                intensity = 0.35
                bedNode.volume = bedVolume
                bedNode.play()
                isRunning = true
            } catch {
                isRunning = false
            }
        }
    }

    public func pause() { queue.async { [self] in if isRunning { engine.pause() } } }

    public func resume() {
        queue.async { [self] in
            guard isRunning, Preferences.crowdEnabled else { return }
            try? engine.start()
        }
    }

    public func stopMatch() {
        queue.async { [self] in
            guard isRunning else { return }
            bedNode.stop()
            reactionNodes.forEach { $0.stop() }
            engine.stop()
            isRunning = false
        }
    }

    /// Lets the murmur settle back down between incidents.
    public func tickMinute() {
        queue.async { [self] in
            intensity = max(0.25, intensity * 0.93)
            bedNode.volume = bedVolume
        }
    }

    private var bedVolume: Float { 0.25 + intensity * 0.55 }

    /// Reacts to an event from the home crowd's point of view.
    public func react(to event: MatchEvent) {
        guard Preferences.crowdEnabled else { return }
        let home = event.isHomeTeam
        let reaction: Reaction?
        var lift: Float = 0
        switch event.type {
        case .goal, .penalty:
            reaction = home ? .roar : .awayRoar
            lift = home ? 0.65 : -0.2
            if !home { play(.groan, volume: 0.9) }
        case .ownGoal:
            reaction = home ? .awayRoar : .roar
            lift = home ? -0.2 : 0.6
        case .woodwork:
            reaction = .ooh; lift = 0.3
        case .chanceMissed, .chance:
            reaction = home ? .groan : .cheer; lift = home ? 0.15 : 0.05
        case .shotOnTarget:
            reaction = home ? .ooh : .applause; lift = 0.2
        case .shotBlocked:
            reaction = home ? .groan : .applause; lift = 0.1
        case .foul:
            reaction = home ? nil : .boo; lift = 0.05
        case .yellowCard:
            reaction = home ? .whistleOfDerision : .cheer; lift = 0.1
        case .redCard, .secondYellow:
            reaction = .gasp; lift = 0.3
            play(home ? .boo : .cheer, volume: 0.9, delay: 0.9)
        case .corner:
            reaction = home ? .chant : nil; lift = 0.1
        case .penaltyMissed:
            reaction = home ? .groan : .roar; lift = 0.3
        case .injury:
            reaction = .applause; lift = -0.05
        case .substitution:
            reaction = home ? .applause : nil
        case .offside:
            reaction = home ? .groan : .cheer
        case .halfTime, .fullTime:
            reaction = .applause
        default:
            reaction = nil
        }
        queue.async { [self] in
            intensity = min(1, max(0.2, intensity + lift))
            bedNode.volume = bedVolume
        }
        if let reaction { play(reaction, volume: 1.0) }
    }

    /// Occasional spontaneous chants when the home side is in charge.
    public func maybeChant(homeLeading: Bool) {
        guard Preferences.crowdEnabled, homeLeading, Int.random(in: 0..<12) == 0 else { return }
        play(.chant, volume: 0.7)
    }

    public func play(_ reaction: Reaction, volume: Float = 1, delay: TimeInterval = 0) {
        queue.asyncAfter(deadline: .now() + delay) { [self] in
            guard isRunning, let buffer = reactions[reaction] else { return }
            let node = reactionNodes[nextReactionNode]
            nextReactionNode = (nextReactionNode + 1) % reactionNodes.count
            node.stop()
            node.volume = volume
            node.scheduleBuffer(buffer, at: nil, options: [])
            node.play()
        }
    }

    // MARK: - Synthesis

    private struct Noise {
        var state: UInt64
        mutating func next() -> Float {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return Float(Int32(truncatingIfNeeded: state >> 32)) / Float(Int32.max)
        }
    }

    /// A two-pole band-pass filter (RBJ cookbook).
    private struct BandPass {
        var b0: Float = 0, b1: Float = 0, b2: Float = 0, a1: Float = 0, a2: Float = 0
        var x1: Float = 0, x2: Float = 0, y1: Float = 0, y2: Float = 0
        init(centre: Float, q: Float, sampleRate: Float = 44_100) { set(centre: centre, q: q, sampleRate: sampleRate) }
        mutating func set(centre: Float, q: Float, sampleRate: Float = 44_100) {
            let w = 2 * Float.pi * centre / sampleRate
            let alpha = sin(w) / (2 * q)
            let a0 = 1 + alpha
            b0 = alpha / a0; b1 = 0; b2 = -alpha / a0
            a1 = -2 * cos(w) / a0; a2 = (1 - alpha) / a0
        }
        mutating func process(_ x: Float) -> Float {
            let y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
            x2 = x1; x1 = x; y2 = y1; y1 = y
            return y
        }
    }

    private func buffer(seconds: Double, render: (Int, Int) -> (Float, Float)) -> AVAudioPCMBuffer {
        let frames = AVAudioFrameCount(seconds * format.sampleRate)
        let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buf.frameLength = frames
        let l = buf.floatChannelData![0], r = buf.floatChannelData![1]
        for i in 0..<Int(frames) {
            let (a, b) = render(i, Int(frames))
            l[i] = max(-1, min(1, a)); r[i] = max(-1, min(1, b))
        }
        return buf
    }

    /// Many overlapping voices: band-limited noise in several formant bands,
    /// each gated at speech-like rates, with the edges crossfaded to loop.
    private func makeBed(seconds: Double) -> AVAudioPCMBuffer {
        var noiseL = Noise(state: 11), noiseR = Noise(state: 29)
        var bandsL = [BandPass(centre: 350, q: 0.9), BandPass(centre: 800, q: 1.2), BandPass(centre: 1500, q: 1.4)]
        var bandsR = [BandPass(centre: 380, q: 0.9), BandPass(centre: 850, q: 1.2), BandPass(centre: 1600, q: 1.4)]
        let rates: [Float] = [3.1, 4.3, 5.7, 2.6, 6.4, 3.9]
        let phases: [Float] = [0.1, 1.7, 2.9, 4.2, 0.8, 5.3]
        let total = Float(seconds * format.sampleRate)
        return buffer(seconds: seconds) { i, frames in
            let t = Float(i) / 44_100
            var gate: Float = 0
            for k in 0..<rates.count { gate += 0.5 + 0.5 * sin(2 * .pi * rates[k] * t + phases[k]) }
            gate /= Float(rates.count)
            let nl = noiseL.next(), nr = noiseR.next()
            var sl: Float = 0, sr: Float = 0
            for k in 0..<3 { sl += bandsL[k].process(nl); sr += bandsR[k].process(nr) }
            // Crossfade the first and last half second so the loop is seamless.
            let edge = min(Float(i), total - Float(i)) / (0.5 * 44_100)
            let fade = min(1, edge)
            let g = (0.55 + 0.45 * gate) * 0.55 * (0.4 + 0.6 * fade)
            return (sl * g, sr * g)
        }
    }

    /// A rising wall of voices with an "aah" formant, used for roars and cheers.
    private func makeSwell(seconds: Double, attack: Float, peak: Float, centre: Float, voice: Bool, seed: UInt64) -> AVAudioPCMBuffer {
        var nl = Noise(state: seed &* 7 &+ 3), nr = Noise(state: seed &* 13 &+ 5)
        var fl = [BandPass(centre: centre * 0.75, q: 1.1), BandPass(centre: centre * 1.35, q: 1.6)]
        var fr = [BandPass(centre: centre * 0.8, q: 1.1), BandPass(centre: centre * 1.4, q: 1.6)]
        let dur = Float(seconds)
        return buffer(seconds: seconds) { i, _ in
            let t = Float(i) / 44_100
            let env = t < attack ? t / attack : max(0, 1 - pow((t - attack) / (dur - attack), 1.6))
            let shimmer: Float = voice ? 0.85 + 0.15 * sin(2 * .pi * 5.5 * t) : 1
            let a = nl.next(), b = nr.next()
            let l = fl[0].process(a) + 0.7 * fl[1].process(a)
            let r = fr[0].process(b) + 0.7 * fr[1].process(b)
            let g = env * peak * shimmer * 1.6
            return (l * g, r * g)
        }
    }

    /// A falling "ohhh" of disappointment.
    private func makeGroan(seconds: Double) -> AVAudioPCMBuffer {
        var n = Noise(state: 77)
        var f1 = BandPass(centre: 600, q: 2.5), f2 = BandPass(centre: 1000, q: 3)
        let dur = Float(seconds)
        return buffer(seconds: seconds) { i, _ in
            let t = Float(i) / 44_100
            let p = t / dur
            f1.set(centre: 620 - 260 * p, q: 2.5); f2.set(centre: 980 - 360 * p, q: 3)
            let env = min(1, t / 0.12) * max(0, 1 - pow(p, 1.4))
            let x = n.next()
            let s = (f1.process(x) + 0.6 * f2.process(x)) * env * 2.4
            return (s, s * 0.95)
        }
    }

    /// The rising-then-falling "ooh" of a near miss.
    private func makeOoh(seconds: Double) -> AVAudioPCMBuffer {
        var n = Noise(state: 91)
        var f1 = BandPass(centre: 400, q: 3), f2 = BandPass(centre: 800, q: 3.5)
        let dur = Float(seconds)
        return buffer(seconds: seconds) { i, _ in
            let t = Float(i) / 44_100
            let p = t / dur
            let bend = sin(.pi * min(1, p * 1.3))
            f1.set(centre: 380 + 220 * bend, q: 3); f2.set(centre: 760 + 300 * bend, q: 3.5)
            let env = min(1, t / 0.08) * max(0, 1 - pow(p, 2))
            let x = n.next()
            let s = (f1.process(x) + 0.5 * f2.process(x)) * env * 2.8
            return (s * 0.95, s)
        }
    }

    /// Low, sustained boos.
    private func makeBoo(seconds: Double) -> AVAudioPCMBuffer {
        var n = Noise(state: 123)
        var f1 = BandPass(centre: 300, q: 4), f2 = BandPass(centre: 520, q: 4)
        let dur = Float(seconds)
        return buffer(seconds: seconds) { i, _ in
            let t = Float(i) / 44_100
            let env = min(1, t / 0.25) * max(0, 1 - pow(t / dur, 2.5))
            let wobble = 1 + 0.08 * sin(2 * .pi * 3 * t)
            f1.set(centre: 300 * wobble, q: 4)
            let x = n.next()
            let s = (f1.process(x) + 0.6 * f2.process(x)) * env * 3.2
            return (s, s)
        }
    }

    /// Thousands of hands: dense random clicks through a high band.
    private func makeApplause(seconds: Double, density: Float) -> AVAudioPCMBuffer {
        var n = Noise(state: 314)
        var bl = BandPass(centre: 2200, q: 0.8), br = BandPass(centre: 2400, q: 0.8)
        var clapL: Float = 0, clapR: Float = 0
        let dur = Float(seconds)
        return buffer(seconds: seconds) { i, _ in
            let t = Float(i) / 44_100
            if abs(n.next()) > 0.9965 - 0.002 * density { clapL = 1 }
            if abs(n.next()) > 0.9965 - 0.002 * density { clapR = 1 }
            clapL *= 0.993; clapR *= 0.993
            let env = min(1, t / 0.2) * max(0, 1 - pow(t / dur, 2))
            let x = n.next(), y = n.next()
            return (bl.process(x * clapL) * env * 2.2, br.process(y * clapR) * env * 2.2)
        }
    }

    /// Clap, clap, clap-clap-clap, with a low drum underneath.
    private func makeChant(seconds: Double) -> AVAudioPCMBuffer {
        var n = Noise(state: 2718)
        var band = BandPass(centre: 1800, q: 1.0)
        var voice = BandPass(centre: 700, q: 2)
        let pattern: [Float] = [0, 0.5, 1.0, 1.25, 1.5]  // beats within a two-second bar
        let dur = Float(seconds)
        return buffer(seconds: seconds) { i, _ in
            let t = Float(i) / 44_100
            let bar = t.truncatingRemainder(dividingBy: 2.0)
            var hit: Float = 0
            for beat in pattern where bar >= beat && bar < beat + 0.06 { hit = 1 - (bar - beat) / 0.06 }
            let x = n.next()
            let clap = band.process(x) * hit * 3.0
            let drum = sin(2 * .pi * 70 * bar) * (pattern.contains { bar >= $0 && bar < $0 + 0.12 } ? 0.5 : 0)
            let sing = voice.process(n.next()) * (0.5 + 0.5 * sin(2 * .pi * 0.5 * t)) * 1.2
            let env = min(1, t / 0.3) * max(0, 1 - pow(t / dur, 3))
            let s = (clap + drum + sing) * env
            return (s, s * 0.97)
        }
    }

    /// Scattered piercing whistles aimed at the referee.
    private func makeWhistles(seconds: Double) -> AVAudioPCMBuffer {
        var n = Noise(state: 999)
        let pitches: [Float] = [2400, 2900, 3300, 2650]
        let starts: [Float] = [0.0, 0.3, 0.55, 0.9]
        let dur = Float(seconds)
        return buffer(seconds: seconds) { i, _ in
            let t = Float(i) / 44_100
            var s: Float = 0
            for k in 0..<pitches.count {
                let local = t - starts[k]
                if local > 0 && local < 1.2 {
                    let env = min(1, local / 0.05) * max(0, 1 - local / 1.2)
                    s += sin(2 * .pi * pitches[k] * local + 0.02 * n.next()) * env * 0.12
                }
            }
            let tail = max(0, 1 - t / dur)
            return (s * tail, s * tail * 0.9)
        }
    }
}
