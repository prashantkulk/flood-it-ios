import AVFoundation
import Foundation

/// Singleton sound manager using AVAudioEngine for programmatic sound synthesis.
/// Sonic palette: water + glass + chimes. Organic, clean, musical.
final class SoundManager {
    static let shared = SoundManager()

    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
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
    var ambientEnabled: Bool = true {
        didSet { UserDefaults.standard.set(ambientEnabled, forKey: Self.kAmbientEnabled) }
    }

    // Ambient state
    private var ambientNode: AVAudioSourceNode?
    private var ambientPhases: [Double] = [0, 0, 0] // C2, G2, C3
    private var ambientVolume: Float = 0.1
    private var ambientTargetVolume: Float = 0.1

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
            ambientEnabled = true
        }
    }

    private func setupAudioSession() {
        do {
            // .ambient respects the hardware mute switch
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)
        } catch {
            print("SoundManager: Audio session setup failed: \(error)")
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
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)
        mixer.outputVolume = masterVolume

        do {
            try engine.start()
        } catch {
            print("SoundManager: Engine start failed: \(error)")
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

    /// Cell absorption 'plip': short sine wave with fast decay (water droplet on glass).
    func playPlip(frequency: Double = 261.63) {
        let dur = 0.08
        playBuffer(duration: dur, volume: 0.25) { i, sr in
            let t = Double(i) / sr
            let envelope = Float(exp(-t * 50)) // fast decay
            let sine = Float(sin(2 * .pi * frequency * t))
            // Add a harmonic for glass-like quality
            let harmonic = Float(sin(2 * .pi * frequency * 2.5 * t)) * 0.3
            return (sine + harmonic) * envelope
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

    /// Win chime: C major chord (C4+E4+G4), 400ms with slow decay.
    func playWinChime() {
        let dur = 0.6
        playBuffer(duration: dur, volume: 0.25) { i, sr in
            let t = Double(i) / sr
            let envelope = Float(exp(-t * 3)) // slow decay
            let c4 = Float(sin(2 * .pi * 261.63 * t))
            let e4 = Float(sin(2 * .pi * 329.63 * t))
            let g4 = Float(sin(2 * .pi * 392.00 * t))
            return (c4 + e4 + g4) / 3.0 * envelope
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

    /// Confetti sparkle: rapid sequence of high-pitched short sines (C5-C6).
    func playConfettiSparkle() {
        guard sfxEnabled else { return }
        let noteCount = 8
        for n in 0..<noteCount {
            let delay = Double(n) * 0.04
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let freq = Double.random(in: 523...1047) // C5-C6
                self.playBuffer(duration: 0.05, volume: 0.12) { i, sr in
                    let t = Double(i) / sr
                    let envelope = Float(exp(-t * 60))
                    return Float(sin(2 * .pi * freq * t)) * envelope
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

    /// C major chord swell for completion rush phase 1.
    func playChordSwell() {
        let dur = 0.5
        playBuffer(duration: dur, volume: 0.25) { i, sr in
            let t = Double(i) / sr
            let progress = t / dur
            // Swell up then gentle decay
            let envelope = Float(sin(.pi * progress) * exp(-progress * 0.5))
            let c4 = Float(sin(2 * .pi * 261.63 * t))
            let e4 = Float(sin(2 * .pi * 329.63 * t))
            let g4 = Float(sin(2 * .pi * 392.00 * t))
            return (c4 + e4 + g4) / 3.0 * envelope
        }
    }

    /// C-E-G-C5-E5 arpeggio, each note 100ms, for completion rush phase 2.
    func playArpeggio() {
        guard sfxEnabled else { return }
        let notes: [Double] = [261.63, 329.63, 392.00, 523.25, 659.25]
        for (index, freq) in notes.enumerated() {
            let delay = Double(index) * 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.playBuffer(duration: 0.15, volume: 0.18) { i, sr in
                    let t = Double(i) / sr
                    let envelope = Float(exp(-t * 12))
                    return Float(sin(2 * .pi * freq * t)) * envelope
                }
            }
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
        let freqs: [Double] = [65.41, 98.0, 130.81] // C2, G2, C3

        let sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, bufferList -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(bufferList)
            let buf = ablPointer[0]
            let data = buf.mData!.assumingMemoryBound(to: Float.self)

            // Smooth volume transitions
            let targetVol = self.ambientEnabled ? self.ambientTargetVolume : 0
            let vol = self.ambientVolume + (targetVol - self.ambientVolume) * 0.001

            for frame in 0..<Int(frameCount) {
                var sample: Float = 0
                for (idx, freq) in freqs.enumerated() {
                    phases[idx] += 2 * .pi * freq / self.sampleRate
                    if phases[idx] > 2 * .pi { phases[idx] -= 2 * .pi }
                    // Slow amplitude modulation
                    let modRate = 0.15 + Double(idx) * 0.05
                    let mod = Float(0.7 + 0.3 * sin(phases[idx] * modRate))
                    sample += Float(sin(phases[idx])) * mod
                }
                data[frame] = sample / 3.0 * vol
            }

            self.ambientPhases = phases
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
    }

    /// Update ambient volume based on flood percentage (0.0-1.0).
    func updateAmbientVolume(floodPercentage: Double) {
        if floodPercentage >= 0.8 {
            ambientTargetVolume = 0.4
        } else if floodPercentage >= 0.5 {
            ambientTargetVolume = Float(0.1 + 0.15 * ((floodPercentage - 0.5) / 0.3))
        } else {
            ambientTargetVolume = 0.1
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
