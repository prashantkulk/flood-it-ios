import SwiftUI

struct SettingsView: View {
    @State private var masterVolume: Double = Double(SoundManager.shared.masterVolume)
    @State private var sfxEnabled: Bool = SoundManager.shared.sfxEnabled
    @State private var ambientEnabled: Bool = SoundManager.shared.ambientEnabled
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("Settings")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            VStack(spacing: 16) {
                // Master volume slider
                VStack(alignment: .leading, spacing: 8) {
                    Text("Volume")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.fill")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 12))
                        Slider(value: $masterVolume, in: 0...1)
                            .tint(.white)
                            .onChange(of: masterVolume) { newValue in
                                SoundManager.shared.setMasterVolume(Float(newValue))
                            }
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 12))
                    }
                }

                // SFX toggle
                Toggle(isOn: $sfxEnabled) {
                    Text("Sound Effects")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                }
                .tint(.white)
                .onChange(of: sfxEnabled) { newValue in
                    SoundManager.shared.setSFXEnabled(newValue)
                }

                // Ambient toggle
                Toggle(isOn: $ambientEnabled) {
                    Text("Ambient Music")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                }
                .tint(.white)
                .onChange(of: ambientEnabled) { newValue in
                    SoundManager.shared.setAmbientEnabled(newValue)
                }
            }

            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.06, green: 0.06, blue: 0.12))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white)
                    .clipShape(Capsule())
            }
            .accessibilityIdentifier("settingsDoneButton")
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .frame(maxWidth: 300)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}
