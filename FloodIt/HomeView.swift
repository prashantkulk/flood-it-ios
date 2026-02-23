import SwiftUI

struct HomeView: View {
    @ObservedObject private var progress = ProgressStore.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.12)
                    .ignoresSafeArea()

                VStack(spacing: 40) {
                    // Streak badge (top right area)
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

                    Text("FLOOD")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(8)

                    Spacer()

                    NavigationLink(destination: LevelSelectView()) {
                        Text("Play")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.06, green: 0.06, blue: 0.12))
                            .padding(.horizontal, 48)
                            .padding(.vertical, 16)
                            .background(.white)
                            .clipShape(Capsule())
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
