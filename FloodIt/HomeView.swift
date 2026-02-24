import SwiftUI

// MARK: - BUG-10: Premium home screen overhaul

struct HomeView: View {
    @ObservedObject private var progress = ProgressStore.shared
    @State private var gradientPhase: CGFloat = 0
    @State private var particles: [FloatingParticle] = FloatingParticle.generate(count: 18)
    @State private var titleGlow: CGFloat = 0.5
    @State private var buttonPulse: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated dark navy gradient background
                animatedBackground

                // Floating color particles
                particleLayer

                // Main content
                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    titleSection
                    Spacer()
                    buttonSection
                    Spacer().frame(height: 60)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                startAnimations()
            }
        }
    }

    // MARK: - Animated Background

    private var animatedBackground: some View {
        ZStack {
            // Base dark navy
            Color(red: 0.04, green: 0.04, blue: 0.10)
                .ignoresSafeArea()

            // Shifting gradient overlay
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.06, blue: 0.22).opacity(0.7),
                    Color(red: 0.04, green: 0.08, blue: 0.20).opacity(0.5),
                    Color(red: 0.06, green: 0.04, blue: 0.15).opacity(0.6),
                ],
                startPoint: UnitPoint(x: 0.3 + 0.2 * sin(gradientPhase), y: 0),
                endPoint: UnitPoint(x: 0.7 + 0.2 * cos(gradientPhase * 0.7), y: 1)
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: gradientPhase)
        }
    }

    // MARK: - Floating Particles

    private var particleLayer: some View {
        GeometryReader { geo in
            ForEach(particles) { p in
                Circle()
                    .fill(p.color.opacity(0.35))
                    .frame(width: p.size, height: p.size)
                    .blur(radius: p.size * 0.4)
                    .position(
                        x: p.x * geo.size.width,
                        y: p.y * geo.size.height
                    )
                    .animation(
                        .easeInOut(duration: p.duration)
                        .repeatForever(autoreverses: true)
                        .delay(p.delay),
                        value: p.y
                    )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Spacer()
            if progress.currentStreak > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.orange)
                    Text("\(progress.currentStreak)")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("day streak")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.15))
                        .overlay(Capsule().stroke(Color.orange.opacity(0.3), lineWidth: 1))
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("FLOOD IT")
                .font(.system(size: 58, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .tracking(6)
                .shadow(color: Color.white.opacity(titleGlow * 0.4), radius: 20, x: 0, y: 0)
                .shadow(color: Color(red: 0.5, green: 0.3, blue: 1.0).opacity(titleGlow * 0.3), radius: 30, x: 0, y: 0)

            Text("Fill the board. Use every move.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1)
        }
    }

    // MARK: - Buttons

    private var buttonSection: some View {
        VStack(spacing: 14) {
            // Primary: Continue Level N — glowing orb style
            NavigationLink(destination: GameView(levelNumber: progress.currentLevel)) {
                ZStack {
                    // Outer glow
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.6, green: 0.8, blue: 1.0).opacity(0.15),
                                    Color(red: 0.4, green: 0.5, blue: 0.9).opacity(0.08),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(buttonPulse)
                        .blur(radius: 8)

                    // Button body
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 20, weight: .semibold))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Continue")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .opacity(0.7)
                            Text("Level \(progress.currentLevel)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .opacity(0.6)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.25, green: 0.35, blue: 0.65),
                                        Color(red: 0.15, green: 0.20, blue: 0.45),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.25), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                }
            }
            .buttonStyle(OrbPressStyle())
            .accessibilityIdentifier("continueLevelButton")

            // Secondary: Daily Challenge
            NavigationLink(destination: DailyChallengeEntryView()) {
                HStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Daily Challenge")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
            }
            .accessibilityIdentifier("dailyChallengeButton")
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Animations

    private func startAnimations() {
        // Gradient shift
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
            gradientPhase = .pi
        }
        // Title glow breathe
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            titleGlow = 1.0
        }
        // Button pulse
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            buttonPulse = 1.06
        }
        // Animate particles floating up/down
        for i in particles.indices {
            let offset = CGFloat.random(in: -0.08...0.08)
            withAnimation(
                .easeInOut(duration: particles[i].duration)
                .repeatForever(autoreverses: true)
                .delay(particles[i].delay)
            ) {
                particles[i].y = max(0.05, min(0.95, particles[i].y + offset))
            }
        }
    }
}

// MARK: - Floating Particle Model

struct FloatingParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let color: Color
    let duration: Double
    let delay: Double

    static func generate(count: Int) -> [FloatingParticle] {
        let colors: [Color] = [
            Color(red: 1.0, green: 0.45, blue: 0.4),   // coral
            Color(red: 1.0, green: 0.75, blue: 0.2),   // amber
            Color(red: 0.25, green: 0.85, blue: 0.55), // emerald
            Color(red: 0.3, green: 0.6, blue: 1.0),    // sapphire
            Color(red: 0.7, green: 0.4, blue: 1.0),    // violet
        ]
        return (0..<count).map { _ in
            FloatingParticle(
                x: CGFloat.random(in: 0.05...0.95),
                y: CGFloat.random(in: 0.05...0.95),
                size: CGFloat.random(in: 12...40),
                color: colors.randomElement()!,
                duration: Double.random(in: 2.5...5.0),
                delay: Double.random(in: 0...3.0)
            )
        }
    }
}

#Preview {
    HomeView()
}
