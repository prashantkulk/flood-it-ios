import SwiftUI

struct HomeView: View {
    @ObservedObject private var progress = ProgressStore.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.12)
                    .ignoresSafeArea()

                VStack(spacing: 40) {
                    // Top row: streak badge + settings
                    HStack {
                        Spacer()
                        if progress.currentStreak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.orange)
                                Text("\(progress.currentStreak)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.white.opacity(0.1)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)

                    Spacer()

                    Text("FLOOD IT")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(8)

                    Spacer()

                    VStack(spacing: 16) {
                        // Primary: Continue Level N
                        NavigationLink(destination: GameView(levelNumber: progress.currentLevel)) {
                            HStack(spacing: 10) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Level \(progress.currentLevel)")
                                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(Color(red: 0.06, green: 0.06, blue: 0.12))
                            .padding(.horizontal, 48)
                            .padding(.vertical, 16)
                            .background(.white)
                            .clipShape(Capsule())
                        }
                        .accessibilityIdentifier("continueLevelButton")

                        NavigationLink(destination: DailyChallengeEntryView()) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Daily Challenge")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .accessibilityIdentifier("dailyChallengeButton")
                    }

                    Spacer()
                        .frame(height: 80)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    HomeView()
}
