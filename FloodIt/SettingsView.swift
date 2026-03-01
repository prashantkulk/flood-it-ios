import SwiftUI

struct SettingsView: View {
    @State private var masterVolume: Double = Double(SoundManager.shared.masterVolume)
    @State private var sfxEnabled: Bool = SoundManager.shared.sfxEnabled
    @State private var ambientEnabled: Bool = SoundManager.shared.ambientEnabled
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var progress = ProgressStore.shared
    @StateObject private var storeManager = StoreManager.shared
    @State private var showRestoreAlert = false
    @State private var restoreSuccess = false
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

                // Ambient music removed — was just noise
            }

            // Theme selector
            VStack(alignment: .leading, spacing: 10) {
                Text("Theme")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                ForEach(ThemeManager.allThemes) { theme in
                    let isActive = themeManager.activeTheme.id == theme.id
                    let unlocked = themeManager.isUnlocked(theme)

                    Button(action: {
                        if unlocked {
                            themeManager.selectTheme(theme)
                        }
                    }) {
                        HStack {
                            // Color preview swatches
                            HStack(spacing: 3) {
                                ForEach(0..<5, id: \.self) { i in
                                    Circle()
                                        .fill(Color(hex: theme.lightColors[i]))
                                        .frame(width: 14, height: 14)
                                }
                            }

                            Text(theme.name)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(unlocked ? .white : .white.opacity(0.4))

                            Spacer()

                            if !unlocked {
                                HStack(spacing: 2) {
                                    Text("\(theme.starsRequired)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(.yellow.opacity(0.7))
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.yellow.opacity(0.7))
                                }
                            } else if isActive {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isActive ? Color.white.opacity(0.12) : Color.clear)
                        )
                    }
                    .disabled(!unlocked)
                }
            }

            // MARK: P12-T4 Remove Ads IAP
            removeAdsSection

            // MARK: P12-T6 Restore Purchases
            if case .purchased = storeManager.purchaseState {
                // Already purchased, no need to show restore
            } else {
                Button(action: {
                    Task {
                        let success = await storeManager.restorePurchases()
                        restoreSuccess = success
                        showRestoreAlert = true
                    }
                }) {
                    Text("Restore Purchases")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                .accessibilityIdentifier("restorePurchasesButton")
                .alert(restoreSuccess ? "Restored!" : "No Purchases Found",
                       isPresented: $showRestoreAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(restoreSuccess
                         ? "Your ad-free purchase has been restored."
                         : "No previous purchases were found for this account.")
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

    @ViewBuilder
    private var removeAdsSection: some View {
        switch storeManager.purchaseState {
        case .purchased:
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                Text("Ad-Free")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
            }
        case .purchasing:
            ProgressView()
                .tint(.white)
        default:
            if let product = storeManager.removeAdsProduct {
                Button(action: {
                    Task { await storeManager.purchaseRemoveAds() }
                }) {
                    HStack {
                        Text("Remove Ads")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                        Spacer()
                        Text(product.displayPrice)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                }
                .accessibilityIdentifier("removeAdsButton")
            }
        }
    }
}
