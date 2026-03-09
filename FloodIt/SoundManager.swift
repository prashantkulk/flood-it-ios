import AVFoundation
import Foundation

/// Singleton sound manager using AVAudioEngine for programmatic sound synthesis.
/// Rich stereo synthesis with detuned L/R channels for width. Marimba/xylophone timbres.
final class SoundManager {
    static let shared = SoundManager()

    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private let reverbNode = AVAudioUnitReverb()
    private let sampleRate: Double = 44100

    // Settings (persisted via UserDefaults)
    private static let kMasterVolume = "sound_masterVolume"
    private static let kSFXEnabled = "sound_sfxEnabled"

    var masterVolume: Float = 0.8 {
        didSet {
            mixer.outputVolume = masterVolume
            UserDefaults.standard.set(masterVolume, forKey: Self.kMasterVolume)
        }
    }
    var sfxEnabled: Bool = true {
        didSet { UserDefaults.standard.set(sfxEnabled, forKey: Self.kSFXEnabled) }
    }

    // Cents detuning for stereo width: +3 left, -3 right
    private let stereoDetuneCents: Double = 3.0

    private init() {
        loadSettings()
        setupAudioSession()
        setupEngine()
    }

    private func loadSettings() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Self.kMasterVolume) != nil {
            masterVolume = defaults.float(forKey: Self.kMasterVolume)
        }
        if defaults.object(forKey: Self.kSFXEnabled) != nil {
            sfxEnabled = defaults.bool(forKey: Self.kSFXEnabled)
        } else {
            sfxEnabled = true
        }
    }

    private func setupAudioSession() {
        do {
            // .ambient respects the hardware mute switch
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)
        } catch {
            // Audio session setup failed — silent fallback
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .ended {
            try? engine.start()
        }
    }

    private func setupEngine() {
        engine.attach(mixer)
        engine.attach(reverbNode)

        // Route: mixer → reverb → mainMixer
        reverbNode.loadFactoryPreset(.mediumHall)
        reverbNode.wetDryMix = 35
        engine.connect(mixer, to: reverbNode, format: nil)
        engine.connect(reverbNode, to: engine.mainMixerNode, format: nil)
        mixer.outputVolume = masterVolume

        do {
            try engine.start()
        } catch {
            // Engine start failed — silent fallback
        }
    }

    // MARK: - Stereo Helpers

    /// Detune factor for cents offset
    private func detuneMultiplier(cents: Double) -> Double {
        pow(2.0, cents / 1200.0)
    }

    // MARK: - Core Synthesis

    /// Play a stereo synthesized sound. Generator receives (sampleIndex, sampleRate, channelIndex)
    /// where channelIndex 0=left, 1=right. Detuning is applied automatically via freq helpers.
    private func playBuffer(duration: TimeInterval, volume: Float = 0.3,
                            generator: @escaping (Int, Double, Int) -> Float) {
        guard sfxEnabled else { return }
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let leftData = buffer.floatChannelData![0]
        let rightData = buffer.floatChannelData![1]
        for i in 0..<Int(frameCount) {
            leftData[i] = generator(i, sampleRate, 0) * volume
            rightData[i] = generator(i, sampleRate, 1) * volume
        }

        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: mixer, format: format)
        player.scheduleBuffer(buffer) {
            DispatchQueue.main.async {
                player.stop()
                self.engine.detach(player)
            }
        }
        player.play()
    }

    /// Get detuned frequency for stereo width. Left channel gets +cents, right gets -cents.
    private func stereoFreq(_ baseFreq: Double, channel: Int) -> Double {
        let cents = channel == 0 ? stereoDetuneCents : -stereoDetuneCents
        return baseFreq * detuneMultiplier(cents: cents)
    }

    /// Smooth envelope: fast attack (attackTime seconds), then shaped decay.
    private func envelope(t: Double, attack: Double, decay: Double, duration: Double) -> Float {
        let atk = Float(min(t / attack, 1.0))
        let progress = t / duration
        // Smooth cosine-shaped decay rather than pure exponential
        let dec = Float(exp(-t * decay) * (1.0 + 0.3 * cos(.pi * progress)))
        return atk * max(dec, 0)
    }

    /// Triangle wave (normalized to -1...1)
    private func triangle(phase: Double) -> Float {
        let p = phase.truncatingRemainder(dividingBy: 1.0)
        return Float(p < 0.5 ? 4.0 * p - 1.0 : 3.0 - 4.0 * p)
    }

    // MARK: - Sound Effects

    /// Cell absorption 'plip': fundamental + 2nd harmonic + 5th harmonic + filtered noise transient.
    /// Xylophone/marimba feel with sharp 2ms attack.
    func playPlip(frequency: Double = 261.63) {
        let dur = 0.16
        playBuffer(duration: dur, volume: 0.26) { [self] i, sr, ch in
            let t = Double(i) / sr
            let f = stereoFreq(frequency, channel: ch)
            let atk = Float(min(t / 0.002, 1.0))  // sharp 2ms attack
            let env = envelope(t: t, attack: 0.002, decay: 32, duration: dur)

            // Fundamental — sine+triangle blend for marimba body
            let sine = Float(sin(2 * .pi * f * t))
            let tri = triangle(phase: f * t) * 0.15
            // 2nd harmonic — brightness
            let h2 = Float(sin(2 * .pi * f * 2.0 * t)) * 0.25
            // 5th harmonic — xylophone shimmer
            let h5 = Float(sin(2 * .pi * f * 5.0 * t)) * 0.08 * Float(exp(-t * 60))
            // Filtered noise transient — sharp click
            let noise = Float.random(in: -1...1) * Float(exp(-t * 300)) * 0.12

            return (sine + tri + h2 + h5 + noise) * env * atk
        }
    }

    /// Button click: short noise burst with bandpass filter feel.
    func playButtonClick(centerFrequency: Double = 1000) {
        let dur = 0.04
        playBuffer(duration: dur, volume: 0.15) { [self] i, sr, ch in
            let t = Double(i) / sr
            let f = stereoFreq(centerFrequency, channel: ch)
            let env = envelope(t: t, attack: 0.001, decay: 80, duration: dur)
            let noise = Float.random(in: -1...1)
            let carrier = Float(sin(2 * .pi * f * t))
            return noise * carrier * env
        }
    }

    /// Cluster whoosh: white noise with rising bandpass sweep, 200ms.
    func playClusterWhoosh() {
        let dur = 0.2
        playBuffer(duration: dur, volume: 0.15) { i, sr, ch in
            let t = Double(i) / sr
            let env = Float(sin(.pi * t / dur))
            let freq = 400 + 2000 * t / dur
            let noise = Float.random(in: -1...1)
            let carrier = Float(sin(2 * .pi * freq * t))
            // Slight L/R offset for width
            let offset = ch == 0 ? 0.0 : 0.0003
            let delayed = Float(sin(2 * .pi * freq * (t + offset)))
            return noise * (carrier * 0.6 + delayed * 0.4) * env
        }
    }

    /// Dam break rumble: low frequency sine with crescendo over 500ms.
    func playDamBreakRumble() {
        let dur = 0.5
        playBuffer(duration: dur, volume: 0.35) { [self] i, sr, ch in
            let t = Double(i) / sr
            let progress = t / dur
            let env = Float(progress * progress)
            let baseFreq = 60 + 20 * sin(2 * .pi * 3 * t)
            let f = stereoFreq(baseFreq, channel: ch)
            let sine = Float(sin(2 * .pi * f * t))
            let sub = Float(sin(2 * .pi * stereoFreq(40, channel: ch) * t)) * 0.4
            return (sine + sub) * env
        }
    }

    /// Deep boom: sine at 60Hz, 300ms, fast decay.
    func playDeepBoom() {
        let dur = 0.3
        playBuffer(duration: dur, volume: 0.35) { [self] i, sr, ch in
            let t = Double(i) / sr
            let env = envelope(t: t, attack: 0.001, decay: 6, duration: dur)
            let sine = Float(sin(2 * .pi * stereoFreq(60, channel: ch) * t))
            let sub = Float(sin(2 * .pi * stereoFreq(30, channel: ch) * t)) * 0.3
            return (sine + sub) * env
        }
    }

    /// Win celebration: 2.5s layered victory jingle.
    /// 0.0s: Big C major chord (C3+C4+E4+G4) with triangle+sine
    /// 0.3s: Quick ascending arpeggio C4-E4-G4-C5 (marimba-like)
    /// 0.7s: Sparkle burst (8 random high notes C6-C7)
    /// 1.0s: Final triumphant Cmaj7 chord (slow 1.5s decay)
    /// Background: filtered noise shimmer (cymbal-like, very quiet)
    func playWinChime() {
        guard sfxEnabled else { return }

        // Phase 1: Big C major chord (0.0s) — triangle + sine blend
        playBuffer(duration: 0.8, volume: 0.26) { [self] i, sr, ch in
            let t = Double(i) / sr
            let atk = Float(min(t / 0.005, 1.0))
            let env = envelope(t: t, attack: 0.005, decay: 2.5, duration: 0.8)

            let c3 = Float(sin(2 * .pi * stereoFreq(130.81, channel: ch) * t)) * 0.5
            let c4 = Float(sin(2 * .pi * stereoFreq(261.63, channel: ch) * t))
            let e4 = Float(sin(2 * .pi * stereoFreq(329.63, channel: ch) * t))
            let g4 = Float(sin(2 * .pi * stereoFreq(392.00, channel: ch) * t))
            // Triangle on root for warmth
            let triC4 = triangle(phase: stereoFreq(261.63, channel: ch) * t) * 0.15
            let triG4 = triangle(phase: stereoFreq(392.00, channel: ch) * t) * 0.10

            return (c3 + c4 + e4 + g4 + triC4 + triG4) / 4.0 * env * atk
        }

        // Phase 2: Quick ascending arpeggio (0.3s) — marimba-like
        let arpNotes: [Double] = [261.63, 329.63, 392.00, 523.25] // C4, E4, G4, C5
        for (idx, freq) in arpNotes.enumerated() {
            let delay = 0.3 + Double(idx) * 0.07
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.playBuffer(duration: 0.15, volume: 0.22) { [self] i, sr, ch in
                    let t = Double(i) / sr
                    let f = stereoFreq(freq, channel: ch)
                    let atk = Float(min(t / 0.002, 1.0))
                    let env = envelope(t: t, attack: 0.002, decay: 18, duration: 0.15)
                    let sine = Float(sin(2 * .pi * f * t))
                    let tri = triangle(phase: f * t) * 0.2
                    let h2 = Float(sin(2 * .pi * f * 2 * t)) * 0.15
                    let h5 = Float(sin(2 * .pi * f * 5 * t)) * 0.06 * Float(exp(-t * 80))
                    return (sine + tri + h2 + h5) * env * atk
                }
            }
        }

        // Phase 3: Sparkle burst (0.7s) — 8 random high notes C6-C7
        for n in 0..<8 {
            let delay = 0.7 + Double(n) * 0.04
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let freq = Double.random(in: 1047...2093) // C6-C7
                self.playBuffer(duration: 0.1, volume: Float.random(in: 0.08...0.14)) { [self] i, sr, ch in
                    let t = Double(i) / sr
                    let f = stereoFreq(freq, channel: ch)
                    let env = envelope(t: t, attack: 0.001, decay: 40, duration: 0.1)
                    let sine = Float(sin(2 * .pi * f * t))
                    let h2 = Float(sin(2 * .pi * f * 2 * t)) * 0.2
                    return (sine + h2) * env
                }
            }
        }

        // Phase 4: Final triumphant Cmaj7 chord (1.0s) — all octaves, slow 1.5s decay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.playBuffer(duration: 1.5, volume: 0.24) { [self] i, sr, ch in
                let t = Double(i) / sr
                let atk = Float(min(t / 0.01, 1.0))
                let env = envelope(t: t, attack: 0.01, decay: 1.8, duration: 1.5)

                let c3 = Float(sin(2 * .pi * stereoFreq(130.81, channel: ch) * t)) * 0.3
                let c4 = Float(sin(2 * .pi * stereoFreq(261.63, channel: ch) * t))
                let e4 = Float(sin(2 * .pi * stereoFreq(329.63, channel: ch) * t))
                let g4 = Float(sin(2 * .pi * stereoFreq(392.00, channel: ch) * t))
                let b4 = Float(sin(2 * .pi * stereoFreq(493.88, channel: ch) * t)) * 0.7
                let c5 = Float(sin(2 * .pi * stereoFreq(523.25, channel: ch) * t)) * 0.5
                let e5 = Float(sin(2 * .pi * stereoFreq(659.25, channel: ch) * t)) * 0.3
                // Triangle body on root
                let tri = triangle(phase: stereoFreq(261.63, channel: ch) * t) * 0.12

                let chord: Float = c3 + c4 + e4 + g4 + b4 + c5 + e5 + tri
                return chord / 5.0 * env * atk
            }
        }

        // Background: filtered noise shimmer (cymbal-like, very quiet, spans full 2.5s)
        let shimmerDur = 2.5
        playBuffer(duration: shimmerDur, volume: 0.04) { i, sr, ch in
            let t = Double(i) / sr
            let sinePart = Float(sin(.pi * t / shimmerDur))
            let decayPart = Float(exp(-t * 0.8))
            let env = sinePart * decayPart
            let noise = Float.random(in: -1...1)
            let carrierFreq = 6000.0 + Double(ch) * 200.0
            let carrier = Float(sin(2.0 * .pi * carrierFreq * t))
            return noise * carrier * env
        }
    }

    /// Lose sound: C minor chord (C4+Eb4+G4) softly, descending bass C3→G2, gentle reverb tail.
    func playLoseTone() {
        let dur = 1.2
        playBuffer(duration: dur, volume: 0.18) { [self] i, sr, ch in
            let t = Double(i) / sr
            let atk = Float(min(t / 0.01, 1.0))
            let env = envelope(t: t, attack: 0.01, decay: 2.0, duration: dur)

            // C minor chord: C4 + Eb4 + G4
            let c4 = Float(sin(2 * .pi * stereoFreq(261.63, channel: ch) * t))
            let eb4 = Float(sin(2 * .pi * stereoFreq(311.13, channel: ch) * t))
            let g4 = Float(sin(2 * .pi * stereoFreq(392.00, channel: ch) * t))

            // Descending bass: C3 (130.81) → G2 (98.0) over first 0.8s
            let bassProgress = min(t / 0.8, 1.0)
            let bassFreq = 130.81 - (130.81 - 98.0) * bassProgress
            let bass = Float(sin(2 * .pi * stereoFreq(bassFreq, channel: ch) * t)) * 0.4
            let bassEnv = Float(exp(-t * 1.5))

            return ((c4 + eb4 + g4) / 3.0 + bass * bassEnv) * env * atk
        }
    }

    /// Confetti sparkle: 16-note burst spanning C5–C7, sparkly and celebratory.
    func playConfettiSparkle() {
        guard sfxEnabled else { return }
        let noteCount = 16
        for n in 0..<noteCount {
            let delay = Double(n) * 0.028
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let freq = Double.random(in: 523...2093)
                let vol = Float.random(in: 0.08...0.14)
                self.playBuffer(duration: 0.07, volume: vol) { [self] i, sr, ch in
                    let t = Double(i) / sr
                    let f = stereoFreq(freq, channel: ch)
                    let env = envelope(t: t, attack: 0.001, decay: 55, duration: 0.07)
                    let sine = Float(sin(2 * .pi * f * t))
                    let harm = Float(sin(2 * .pi * f * 2 * t)) * 0.2
                    return (sine + harm) * env
                }
            }
        }
    }

    /// Star chime: individual notes do(C5), mi(E5), sol(G5), each 200ms.
    func playStarChime(noteIndex: Int) {
        let frequencies: [Double] = [523.25, 659.25, 783.99]
        guard noteIndex >= 0 && noteIndex < frequencies.count else { return }
        let freq = frequencies[noteIndex]
        let dur = 0.25
        playBuffer(duration: dur, volume: 0.22) { [self] i, sr, ch in
            let t = Double(i) / sr
            let f = stereoFreq(freq, channel: ch)
            let env = envelope(t: t, attack: 0.002, decay: 6, duration: dur)
            let sine = Float(sin(2 * .pi * f * t))
            let tri = triangle(phase: f * t) * 0.12
            let h2 = Float(sin(2 * .pi * f * 2 * t)) * 0.2
            return (sine + tri + h2) * env
        }
    }

    /// Rapid-fire plip torrent with random pitches (C4-C6) for dam-break finale.
    func playPlipTorrent(count: Int = 12, over duration: TimeInterval = 0.4) {
        guard sfxEnabled else { return }
        for n in 0..<count {
            let delay = Double(n) * (duration / Double(count))
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let freq = Double.random(in: 261...1047)
                self.playPlip(frequency: freq)
            }
        }
    }

    /// Cmaj7 chord swell for completion rush phase 1 — triumphant, full, layered.
    func playChordSwell() {
        let dur = 0.8
        playBuffer(duration: dur, volume: 0.28) { [self] i, sr, ch in
            let t = Double(i) / sr
            let progress = t / dur
            let env = Float(sin(.pi * progress) * exp(-progress * 0.4))
            let c4 = Float(sin(2 * .pi * stereoFreq(261.63, channel: ch) * t))
            let e4 = Float(sin(2 * .pi * stereoFreq(329.63, channel: ch) * t))
            let g4 = Float(sin(2 * .pi * stereoFreq(392.00, channel: ch) * t))
            let b4 = Float(sin(2 * .pi * stereoFreq(493.88, channel: ch) * t))
            let c5 = Float(sin(2 * .pi * stereoFreq(523.25, channel: ch) * t)) * 0.45
            let tri = triangle(phase: stereoFreq(261.63, channel: ch) * t) * 0.10
            return (c4 + e4 + g4 + b4 + c5 + tri) / 4.8 * env
        }
    }

    /// Rising Cmaj7 arpeggio (C4→E4→G4→B4→C5→E5→G5) with triangle harmonics.
    func playArpeggio() {
        guard sfxEnabled else { return }
        let notes: [Double] = [261.63, 329.63, 392.00, 493.88, 523.25, 659.25, 783.99]
        for (index, freq) in notes.enumerated() {
            let delay = Double(index) * 0.085
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.playBuffer(duration: 0.18, volume: 0.20) { [self] i, sr, ch in
                    let t = Double(i) / sr
                    let f = stereoFreq(freq, channel: ch)
                    let env = envelope(t: t, attack: 0.002, decay: 10, duration: 0.18)
                    let sine = Float(sin(2 * .pi * f * t))
                    let harm = Float(sin(2 * .pi * f * 2 * t)) * 0.22
                    let tri = triangle(phase: f * t) * 0.12
                    return (sine + harm + tri) * env
                }
            }
        }
    }

    // MARK: - Obstacle Audio

    /// Ice crack sound: sharp noise burst with high-frequency pop.
    func playCrack() {
        let dur = 0.12
        playBuffer(duration: dur, volume: 0.20) { [self] i, sr, ch in
            let t = Double(i) / sr
            let env = envelope(t: t, attack: 0.0005, decay: 40, duration: dur)
            let noise = Float.random(in: -1...1) * 0.5
            let crack = Float(sin(2 * .pi * stereoFreq(3000, channel: ch) * t)) * 0.5
            return (noise + crack) * env
        }
    }

    /// Countdown explosion: low boom + noise burst.
    func playCountdownExplosion() {
        let dur = 0.25
        playBuffer(duration: dur, volume: 0.25) { [self] i, sr, ch in
            let t = Double(i) / sr
            let env = envelope(t: t, attack: 0.001, decay: 10, duration: dur)
            let boom = Float(sin(2 * .pi * stereoFreq(80, channel: ch) * t)) * 0.6
            let noise = Float.random(in: -1...1) * Float(exp(-t * 20)) * 0.4
            return (boom + noise) * env
        }
    }

    /// Defuse chime: short pleasant ascending tone.
    func playDefuseChime() {
        let dur = 0.15
        playBuffer(duration: dur, volume: 0.20) { [self] i, sr, ch in
            let t = Double(i) / sr
            let freq = 600 + 400 * t / dur
            let env = envelope(t: t, attack: 0.001, decay: 15, duration: dur)
            return Float(sin(2 * .pi * stereoFreq(freq, channel: ch) * t)) * env
        }
    }

    /// Cha-ching: bright two-tone chime for bonus tile collection.
    func playChaChing() {
        guard sfxEnabled else { return }
        playBuffer(duration: 0.15, volume: 0.22) { [self] i, sr, ch in
            let t = Double(i) / sr
            let env = envelope(t: t, attack: 0.001, decay: 18, duration: 0.15)
            let f1 = Float(sin(2 * .pi * stereoFreq(1318.5, channel: ch) * t))
            let f2 = Float(sin(2 * .pi * stereoFreq(1568.0, channel: ch) * t)) * 0.5
            return (f1 + f2) * env
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.playBuffer(duration: 0.2, volume: 0.22) { [self] i, sr, ch in
                let t = Double(i) / sr
                let env = envelope(t: t, attack: 0.001, decay: 12, duration: 0.2)
                let f1 = Float(sin(2 * .pi * stereoFreq(2093.0, channel: ch) * t))
                let f2 = Float(sin(2 * .pi * stereoFreq(2637.0, channel: ch) * t)) * 0.3
                return (f1 + f2) * env
            }
        }
    }

    // MARK: - Cascade Audio

    /// Cascade whoosh: layered noise + sine sweep, escalating pitch and volume per round.
    func playCascadeWhoosh(round: Int = 0) {
        let dur = 0.28 + Double(round) * 0.04
        let basePitch = 900.0 + Double(round) * 350.0
        let vol = Float(min(0.16 + Double(round) * 0.07, 0.36))
        playBuffer(duration: dur, volume: vol) { [self] i, sr, ch in
            let t = Double(i) / sr
            let env = Float(sin(.pi * t / dur))
            let freq = basePitch + 3200 * t / dur
            let noise = Float.random(in: -1...1) * 0.45
            let sine = Float(sin(2 * .pi * stereoFreq(freq, channel: ch) * t)) * 0.35
            let tri = triangle(phase: freq / 800 * t) * 0.20
            return (noise + sine + tri) * env
        }
        if round >= 2 {
            let stabFreq = 80.0 + Double(round) * 25.0
            let stabVol = Float(min(0.10 + Double(round) * 0.04, 0.22))
            playBuffer(duration: 0.3, volume: stabVol) { [self] i, sr, ch in
                let t = Double(i) / sr
                let env = envelope(t: t, attack: 0.002, decay: 7, duration: 0.3)
                let sine = Float(sin(2 * .pi * stereoFreq(stabFreq, channel: ch) * t))
                let sub = Float(sin(2 * .pi * stereoFreq(stabFreq * 0.5, channel: ch) * t)) * 0.4
                return (sine + sub) * env
            }
        }
    }

    /// Crescendo bass swell for long cascade chains (3+): layered sub-bass + growl.
    func playCascadeBassSwell() {
        let dur = 0.75
        playBuffer(duration: dur, volume: 0.24) { [self] i, sr, ch in
            let t = Double(i) / sr
            let progress = t / dur
            let env = Float(sin(.pi * progress) * sqrt(progress))
            let wobble = 55 + 30 * sin(2 * .pi * 3 * t)
            let sine = Float(sin(2 * .pi * stereoFreq(wobble, channel: ch) * t))
            let sub = Float(sin(2 * .pi * stereoFreq(35, channel: ch) * t)) * 0.35
            let tri = triangle(phase: wobble * t / 100) * 0.20
            return (sine + sub + tri) * env
        }
    }

    // MARK: - Combo Audio

    /// Plip with longer reverb tail for combo x2+.
    func playComboPlip(frequency: Double = 261.63) {
        let dur = 0.2
        playBuffer(duration: dur, volume: 0.28) { [self] i, sr, ch in
            let t = Double(i) / sr
            let f = stereoFreq(frequency, channel: ch)
            let env = envelope(t: t, attack: 0.002, decay: 15, duration: dur)
            let sine = Float(sin(2 * .pi * f * t))
            let harmonic = Float(sin(2 * .pi * f * 2.5 * t)) * 0.3
            let reverbTail = Float(sin(2 * .pi * (f * 1.005) * t)) * 0.15 * Float(exp(-t * 10))
            return (sine + harmonic + reverbTail) * env
        }
    }

    /// Low bass throb for combo x3+: 80Hz sine pulse, very quiet.
    func playBassThob() {
        let dur = 0.25
        playBuffer(duration: dur, volume: 0.12) { [self] i, sr, ch in
            let t = Double(i) / sr
            let progress = t / dur
            let env = Float(sin(.pi * progress))
            let sine = Float(sin(2 * .pi * stereoFreq(80, channel: ch) * t))
            let sub = Float(sin(2 * .pi * stereoFreq(40, channel: ch) * t)) * 0.3
            return (sine + sub) * env
        }
    }

    /// Short 'tink' on combo break: high sine with very fast decay.
    func playComboBreakTink() {
        let dur = 0.1
        playBuffer(duration: dur, volume: 0.18) { [self] i, sr, ch in
            let t = Double(i) / sr
            let env = envelope(t: t, attack: 0.0005, decay: 70, duration: dur)
            let f1 = Float(sin(2 * .pi * stereoFreq(2093, channel: ch) * t))
            let f2 = Float(sin(2 * .pi * stereoFreq(2637, channel: ch) * t)) * 0.4
            return (f1 + f2) * env
        }
    }

    // MARK: - Settings

    func setMasterVolume(_ volume: Float) {
        masterVolume = max(0, min(1, volume))
    }

    func setSFXEnabled(_ enabled: Bool) {
        sfxEnabled = enabled
    }
}
