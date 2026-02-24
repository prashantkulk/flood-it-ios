import AVFoundation
import Foundation

/// Singleton sound manager using AVAudioEngine for programmatic sound synthesis.
/// Sonic palette: water + glass + chimes. Organic, clean, musical.
final class SoundManager {
    static let shared = SoundManager()

    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private let reverbNode = AVAudioUnitReverb()
    private let sampleRate: Double = 44100

    // Settings (persisted via UserDefaults)
    private static let kMasterVolume = "sound_masterVolume"
    private static let kSFXEnabled = "sound_sfxEnabled"
    private static let kAmbientEnabled = "sound_ambientEnabled"

    var masterVolume: Float = 0.8 {
        didSet {
            mixer.outputVolume = masterVolume
            UserDefaults.standard.set(masterVolume, forKey: Self.kMasterVolume)
        }
    }
    var sfxEnabled: Bool = true {
        didSet { UserDefaults.standard.set(sfxEnabled, forKey: Self.kSFXEnabled) }
    }
    var ambientEnabled: Bool = false {
        didSet { UserDefaults.standard.set(ambientEnabled, forKey: Self.kAmbientEnabled) }
    }

    // Ambient state
    private var ambientNode: AVAudioSourceNode?
    private var ambientPhases: [Double] = [0, 0, 0] // C2, G2, C3
    private var ambientLFOPhases: [Double] = [0, 0, 0] // Separate slow LFO phases
    private var ambientVolume: Float = 0.0
    private var ambientTargetVolume: Float = 0.05

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
        if defaults.object(forKey: Self.kAmbientEnabled) != nil {
            ambientEnabled = defaults.bool(forKey: Self.kAmbientEnabled)
        } else {
            ambientEnabled = false // default off — user can enable in settings
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
        reverbNode.loadFactoryPreset(.smallRoom)
        reverbNode.wetDryMix = 18  // subtle warmth without muddiness
        engine.connect(mixer, to: reverbNode, format: nil)
        engine.connect(reverbNode, to: engine.mainMixerNode, format: nil)
        mixer.outputVolume = masterVolume

        do {
            try engine.start()
        } catch {
            // Engine start failed — silent fallback
        }
    }

    // MARK: - Core Synthesis

    /// Play a short synthesized sound by providing a render block.
    /// The block receives (sampleIndex, sampleRate) and returns a mono sample.
    private func playBuffer(duration: TimeInterval, volume: Float = 0.3,
                            generator: @escaping (Int, Double) -> Float) {
        guard sfxEnabled else { return }
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            data[i] = generator(i, sampleRate) * volume
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

    // MARK: - Sound Effects

    /// Cell absorption 'plip': layered sine + triangle + transient noise burst (glass-on-water).
    func playPlip(frequency: Double = 261.63) {
        let dur = 0.14
        playBuffer(duration: dur, volume: 0.24) { i, sr in
            let t = Double(i) / sr
            let atk = Float(min(t * 180, 1.0))           // soft 5ms attack
            let envelope = Float(exp(-t * 38))

            let sine = Float(sin(2 * .pi * frequency * t))
            // Triangle upper harmonic — wood-block body
            let triFreq = frequency * 1.5
            let triPhase = (triFreq * t).truncatingRemainder(dividingBy: 1.0)
            let triangle = Float(triPhase < 0.5 ? 4.0*triPhase - 1.0 : 3.0 - 4.0*triPhase) * 0.22
            // 2nd harmonic for brightness
            let harmonic = Float(sin(2 * .pi * frequency * 2.0 * t)) * 0.18
            // Transient click (decays very fast)
            let click = Float.random(in: -1...1) * Float(exp(-t * 200)) * 0.10

            return (sine + triangle + harmonic + click) * envelope * atk
        }
    }

    /// Button click: short noise burst with bandpass filter feel.
    func playButtonClick(centerFrequency: Double = 1000) {
        let dur = 0.04
        playBuffer(duration: dur, volume: 0.15) { i, sr in
            let t = Double(i) / sr
            let envelope = Float(exp(-t * 80))
            // Simulate bandpass with modulated noise
            let noise = Float.random(in: -1...1)
            let carrier = Float(sin(2 * .pi * centerFrequency * t))
            return noise * carrier * envelope
        }
    }

    /// Cluster whoosh: white noise with rising bandpass sweep, 200ms.
    func playClusterWhoosh() {
        let dur = 0.2
        playBuffer(duration: dur, volume: 0.15) { i, sr in
            let t = Double(i) / sr
            let envelope = Float(sin(.pi * t / dur)) // bell curve
            let freq = 400 + 2000 * t / dur // rising sweep
            let noise = Float.random(in: -1...1)
            let carrier = Float(sin(2 * .pi * freq * t))
            return noise * carrier * envelope
        }
    }

    /// Dam break rumble: low frequency sine with crescendo over 500ms.
    func playDamBreakRumble() {
        let dur = 0.5
        playBuffer(duration: dur, volume: 0.35) { i, sr in
            let t = Double(i) / sr
            let progress = t / dur
            let envelope = Float(progress * progress) // crescendo
            let freq = 60 + 20 * sin(2 * .pi * 3 * t) // slight wobble 60-80Hz
            let sine = Float(sin(2 * .pi * freq * t))
            let sub = Float(sin(2 * .pi * 40 * t)) * 0.4
            return (sine + sub) * envelope
        }
    }

    /// Deep boom: sine at 60Hz, 300ms, fast decay.
    func playDeepBoom() {
        let dur = 0.3
        playBuffer(duration: dur, volume: 0.35) { i, sr in
            let t = Double(i) / sr
            let envelope = Float(exp(-t * 6))
            let sine = Float(sin(2 * .pi * 60 * t))
            let sub = Float(sin(2 * .pi * 30 * t)) * 0.3
            return (sine + sub) * envelope
        }
    }

    /// Win chime: Cmaj7 chord (C4+E4+G4+B4) with harmonics — triumphant and full.
    func playWinChime() {
        let dur = 1.0
        playBuffer(duration: dur, volume: 0.28) { i, sr in
            let t = Double(i) / sr
            let atk = Float(min(t * 20, 1.0))
            let envelope = Float(exp(-t * 2.0)) // slow, ringing decay
            let c4 = Float(sin(2 * .pi * 261.63 * t))
            let e4 = Float(sin(2 * .pi * 329.63 * t))
            let g4 = Float(sin(2 * .pi * 392.00 * t))
            let b4 = Float(sin(2 * .pi * 493.88 * t))   // major 7th
            let c5 = Float(sin(2 * .pi * 523.25 * t)) * 0.4  // octave shimmer
            // Triangle body on root
            let triPhase = (261.63 * t).truncatingRemainder(dividingBy: 1.0)
            let tri = Float(triPhase < 0.5 ? 4*triPhase-1 : 3-4*triPhase) * 0.12
            return (c4 + e4 + g4 + b4 + c5 + tri) / 4.8 * envelope * atk
        }
    }

    /// Lose tone: single descending sine (A3 → E3), 600ms, gentle.
    func playLoseTone() {
        let dur = 0.6
        playBuffer(duration: dur, volume: 0.2) { i, sr in
            let t = Double(i) / sr
            let progress = t / dur
            let envelope = Float(exp(-t * 2.5))
            // Descend from A3 (220Hz) to E3 (164.81Hz)
            let freq = 220 - (220 - 164.81) * progress
            let sine = Float(sin(2 * .pi * freq * t))
            return sine * envelope
        }
    }

    /// Confetti sparkle: 16-note burst spanning C5–C7, sparkly and celebratory.
    func playConfettiSparkle() {
        guard sfxEnabled else { return }
        let noteCount = 16
        for n in 0..<noteCount {
            let delay = Double(n) * 0.028
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let freq = Double.random(in: 523...2093) // C5–C7
                let vol = Float.random(in: 0.08...0.14)
                self.playBuffer(duration: 0.07, volume: vol) { i, sr in
                    let t = Double(i) / sr
                    let envelope = Float(exp(-t * 55))
                    let sine = Float(sin(2 * .pi * freq * t))
                    let harm = Float(sin(2 * .pi * freq * 2 * t)) * 0.2
                    return (sine + harm) * envelope
                }
            }
        }
    }

    /// Star chime: individual notes do(C5), mi(E5), sol(G5), each 200ms.
    /// Call with noteIndex 0, 1, 2 for the three stars.
    func playStarChime(noteIndex: Int) {
        let frequencies: [Double] = [523.25, 659.25, 783.99] // C5, E5, G5
        guard noteIndex >= 0 && noteIndex < frequencies.count else { return }
        let freq = frequencies[noteIndex]
        let dur = 0.25
        playBuffer(duration: dur, volume: 0.22) { i, sr in
            let t = Double(i) / sr
            let envelope = Float(exp(-t * 6))
            let sine = Float(sin(2 * .pi * freq * t))
            let harmonic = Float(sin(2 * .pi * freq * 2 * t)) * 0.2
            return (sine + harmonic) * envelope
        }
    }

    /// Rapid-fire plip torrent with random pitches (C4-C6) for dam-break finale.
    func playPlipTorrent(count: Int = 12, over duration: TimeInterval = 0.4) {
        guard sfxEnabled else { return }
        for n in 0..<count {
            let delay = Double(n) * (duration / Double(count))
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let freq = Double.random(in: 261...1047) // C4-C6
                self.playPlip(frequency: freq)
            }
        }
    }

    /// Cmaj7 chord swell for completion rush phase 1 — triumphant, full, layered.
    func playChordSwell() {
        let dur = 0.8
        playBuffer(duration: dur, volume: 0.28) { i, sr in
            let t = Double(i) / sr
            let progress = t / dur
            let envelope = Float(sin(.pi * progress) * exp(-progress * 0.4))
            let c4 = Float(sin(2 * .pi * 261.63 * t))
            let e4 = Float(sin(2 * .pi * 329.63 * t))
            let g4 = Float(sin(2 * .pi * 392.00 * t))
            let b4 = Float(sin(2 * .pi * 493.88 * t))
            let c5 = Float(sin(2 * .pi * 523.25 * t)) * 0.45
            // Warm triangle on root for body
            let triPhase = (261.63 * t).truncatingRemainder(dividingBy: 1.0)
            let tri = Float(triPhase < 0.5 ? 4*triPhase-1 : 3-4*triPhase) * 0.10
            return (c4 + e4 + g4 + b4 + c5 + tri) / 4.8 * envelope
        }
    }

    /// Rising Cmaj7 arpeggio (C4→E4→G4→B4→C5→E5→G5) with triangle harmonics.
    func playArpeggio() {
        guard sfxEnabled else { return }
        let notes: [Double] = [261.63, 329.63, 392.00, 493.88, 523.25, 659.25, 783.99]
        for (index, freq) in notes.enumerated() {
            let delay = Double(index) * 0.085
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.playBuffer(duration: 0.18, volume: 0.20) { i, sr in
                    let t = Double(i) / sr
                    let envelope = Float(exp(-t * 10))
                    let sine = Float(sin(2 * .pi * freq * t))
                    let harm = Float(sin(2 * .pi * freq * 2 * t)) * 0.22
                    let triPhase = (freq * t).truncatingRemainder(dividingBy: 1.0)
                    let tri = Float(triPhase < 0.5 ? 4*triPhase-1 : 3-4*triPhase) * 0.12
                    return (sine + harm + tri) * envelope
                }
            }
        }
    }

    // MARK: - Obstacle Audio

    /// Ice crack sound: sharp noise burst with high-frequency pop.
    func playCrack() {
        let dur = 0.12
        playBuffer(duration: dur, volume: 0.20) { i, sr in
            let t = Double(i) / sr
            let envelope = Float(exp(-t * 40))
            let noise = Float.random(in: -1...1) * 0.5
            let crack = Float(sin(2 * .pi * 3000 * t)) * 0.5
            return (noise + crack) * envelope
        }
    }

    /// Countdown explosion: low boom + noise burst.
    func playCountdownExplosion() {
        let dur = 0.25
        playBuffer(duration: dur, volume: 0.25) { i, sr in
            let t = Double(i) / sr
            let envelope = Float(exp(-t * 10))
            let boom = Float(sin(2 * .pi * 80 * t)) * 0.6
            let noise = Float.random(in: -1...1) * Float(exp(-t * 20)) * 0.4
            return (boom + noise) * envelope
        }
    }

    /// Defuse chime: short pleasant ascending tone.
    func playDefuseChime() {
        let dur = 0.15
        playBuffer(duration: dur, volume: 0.20) { i, sr in
            let t = Double(i) / sr
            let freq = 600 + 400 * t / dur
            let envelope = Float(exp(-t * 15))
            return Float(sin(2 * .pi * freq * t)) * envelope
        }
    }

    /// Cha-ching: bright two-tone chime for bonus tile collection.
    func playChaChing() {
        guard sfxEnabled else { return }
        // First note: high bright tone
        playBuffer(duration: 0.15, volume: 0.22) { i, sr in
            let t = Double(i) / sr
            let envelope = Float(exp(-t * 18))
            let f1 = Float(sin(2 * .pi * 1318.5 * t)) // E6
            let f2 = Float(sin(2 * .pi * 1568.0 * t)) * 0.5 // G6
            return (f1 + f2) * envelope
        }
        // Second note: even higher, slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.playBuffer(duration: 0.2, volume: 0.22) { i, sr in
                let t = Double(i) / sr
                let envelope = Float(exp(-t * 12))
                let f1 = Float(sin(2 * .pi * 2093.0 * t)) // C7
                let f2 = Float(sin(2 * .pi * 2637.0 * t)) * 0.3 // E7
                return (f1 + f2) * envelope
            }
        }
    }

    // MARK: - Cascade Audio

    /// Cascade whoosh: layered noise + sine sweep, escalating pitch and volume per round.
    func playCascadeWhoosh(round: Int = 0) {
        let dur = 0.28 + Double(round) * 0.04
        let basePitch = 900.0 + Double(round) * 350.0
        let vol = Float(min(0.16 + Double(round) * 0.07, 0.36))
        playBuffer(duration: dur, volume: vol) { i, sr in
            let t = Double(i) / sr
            let envelope = Float(sin(.pi * t / dur))
            let freq = basePitch + 3200 * t / dur
            let noise = Float.random(in: -1...1) * 0.45
            let sine  = Float(sin(2 * .pi * freq * t)) * 0.35
            // Triangle sweep for brightness
            let triPhase = (freq / 800 * t).truncatingRemainder(dividingBy: 1.0)
            let tri = Float(triPhase < 0.5 ? 4*triPhase-1 : 3-4*triPhase) * 0.20
            return (noise + sine + tri) * envelope
        }
        // Round 2+: add a deep stab for dramatic impact
        if round >= 2 {
            let stabFreq = 80.0 + Double(round) * 25.0
            let stabVol = Float(min(0.10 + Double(round) * 0.04, 0.22))
            playBuffer(duration: 0.3, volume: stabVol) { i, sr in
                let t = Double(i) / sr
                let envelope = Float(exp(-t * 7))
                let sine = Float(sin(2 * .pi * stabFreq * t))
                let sub  = Float(sin(2 * .pi * stabFreq * 0.5 * t)) * 0.4
                return (sine + sub) * envelope
            }
        }
    }

    /// Crescendo bass swell for long cascade chains (3+): layered sub-bass + growl.
    func playCascadeBassSwell() {
        let dur = 0.75
        playBuffer(duration: dur, volume: 0.24) { i, sr in
            let t = Double(i) / sr
            let progress = t / dur
            let envelope = Float(sin(.pi * progress) * sqrt(progress))
            let wobble = 55 + 30 * sin(2 * .pi * 3 * t)
            let sine = Float(sin(2 * .pi * wobble * t))
            let sub  = Float(sin(2 * .pi * 35 * t)) * 0.35
            // Triangle for growl
            let triPhase = (wobble * t / 100).truncatingRemainder(dividingBy: 1.0)
            let tri = Float(triPhase < 0.5 ? 4*triPhase-1 : 3-4*triPhase) * 0.20
            return (sine + sub + tri) * envelope
        }
    }

    // MARK: - Combo Audio

    /// Plip with longer reverb tail for combo x2+.
    func playComboPlip(frequency: Double = 261.63) {
        let dur = 0.2 // longer than normal 0.08
        playBuffer(duration: dur, volume: 0.28) { i, sr in
            let t = Double(i) / sr
            let envelope = Float(exp(-t * 15)) // slower decay than normal (50)
            let sine = Float(sin(2 * .pi * frequency * t))
            let harmonic = Float(sin(2 * .pi * frequency * 2.5 * t)) * 0.3
            // Add reverb-like tail with detuned copy
            let reverbTail = Float(sin(2 * .pi * (frequency * 1.005) * t)) * 0.15 * Float(exp(-t * 10))
            return (sine + harmonic + reverbTail) * envelope
        }
    }

    /// Low bass throb for combo x3+: 80Hz sine pulse, very quiet.
    func playBassThob() {
        let dur = 0.25
        playBuffer(duration: dur, volume: 0.12) { i, sr in
            let t = Double(i) / sr
            let progress = t / dur
            // Bell-shaped envelope
            let envelope = Float(sin(.pi * progress))
            let sine = Float(sin(2 * .pi * 80 * t))
            let sub = Float(sin(2 * .pi * 40 * t)) * 0.3
            return (sine + sub) * envelope
        }
    }

    /// Short 'tink' on combo break: high sine with very fast decay.
    func playComboBreakTink() {
        let dur = 0.1
        playBuffer(duration: dur, volume: 0.18) { i, sr in
            let t = Double(i) / sr
            let envelope = Float(exp(-t * 70))
            // High pitched metallic tink
            let f1 = Float(sin(2 * .pi * 2093 * t)) // C7
            let f2 = Float(sin(2 * .pi * 2637 * t)) * 0.4 // E7
            return (f1 + f2) * envelope
        }
    }

    // MARK: - Ambient Layer

    func startAmbient() {
        guard ambientEnabled, ambientNode == nil else { return }

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        var phases = ambientPhases
        var lfoPhases = ambientLFOPhases
        // Warm pad: C2, G2, C3 — pure sine for warmth (no harsh harmonics)
        let freqs: [Double] = [65.41, 98.0, 130.81]
        // Separate slow LFO rates (0.07–0.13 Hz) — gentle breathing, not buzzy
        let lfoRates: [Double] = [0.07, 0.11, 0.09]
        // One-pole LP filter state for warmth (cutoff ~1200 Hz)
        var lpY: Float = 0

        let sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, bufferList -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(bufferList)
            let data = ablPointer[0].mData!.assumingMemoryBound(to: Float.self)

            // Copy shared state at start of render cycle to avoid data races
            let enabled = self.ambientEnabled
            let targetVol = self.ambientTargetVolume
            let rate = self.sampleRate

            // LP filter coefficient
            let lpAlpha = Float(1.0 - exp(-2.0 * .pi * 1200.0 / rate))

            var vol = self.ambientVolume
            let targetV = enabled ? targetVol : Float(0)

            for frame in 0..<Int(frameCount) {
                // Smooth volume ramp per-sample (avoids zipper noise)
                vol += (targetV - vol) * 0.0008

                var sample: Float = 0
                for idx in 0..<3 {
                    // Audio oscillator phase
                    phases[idx] += 2 * .pi * freqs[idx] / rate
                    if phases[idx] > 2 * .pi { phases[idx] -= 2 * .pi }
                    // Slow LFO phase (completely separate from audio phase)
                    lfoPhases[idx] += 2 * .pi * lfoRates[idx] / rate
                    if lfoPhases[idx] > 2 * .pi { lfoPhases[idx] -= 2 * .pi }
                    let mod = Float(0.60 + 0.40 * sin(lfoPhases[idx]))
                    sample += Float(sin(phases[idx])) * mod
                }
                // Apply one-pole low-pass for warmth
                lpY = lpAlpha * (sample / 3.0) + (1.0 - lpAlpha) * lpY
                data[frame] = lpY * vol
            }

            self.ambientPhases = phases
            self.ambientLFOPhases = lfoPhases
            self.ambientVolume = vol
            return noErr
        }

        ambientNode = sourceNode
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mixer, format: format)
    }

    func stopAmbient() {
        guard let node = ambientNode else { return }
        engine.detach(node)
        ambientNode = nil
        ambientPhases = [0, 0, 0]
        ambientLFOPhases = [0, 0, 0]
        ambientVolume = 0.0
    }

    /// Update ambient volume based on flood percentage (0.0-1.0). Max 0.15 — subtle warmth.
    func updateAmbientVolume(floodPercentage: Double) {
        if floodPercentage >= 0.8 {
            ambientTargetVolume = 0.15
        } else if floodPercentage >= 0.5 {
            ambientTargetVolume = Float(0.05 + 0.10 * ((floodPercentage - 0.5) / 0.3))
        } else {
            ambientTargetVolume = 0.05
        }
    }

    // MARK: - Settings

    func setMasterVolume(_ volume: Float) {
        masterVolume = max(0, min(1, volume))
    }

    func setSFXEnabled(_ enabled: Bool) {
        sfxEnabled = enabled
    }

    func setAmbientEnabled(_ enabled: Bool) {
        ambientEnabled = enabled
        if enabled {
            startAmbient()
        } else {
            stopAmbient()
        }
    }
}
