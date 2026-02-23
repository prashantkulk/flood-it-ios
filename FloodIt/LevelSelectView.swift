import SwiftUI

struct LevelSelectView: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.12)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Pack header: Splash
                packHeader(title: "Splash", subtitle: "Levels 1–50")

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        // Splash levels 1-50
                        ForEach(LevelStore.levels.prefix(50)) { level in
                            NavigationLink(destination: GameView(levelNumber: level.id)) {
                                LevelCell(level: level, stars: 0, isUnlocked: true)
                            }
                            .buttonStyle(.plain)
                        }

                        // Current pack header (inline)
                        Section {
                            ForEach(LevelStore.levels.dropFirst(50).prefix(50)) { level in
                                NavigationLink(destination: GameView(levelNumber: level.id)) {
                                    LevelCell(level: level, stars: 0, isUnlocked: true)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            HStack {
                                Text("Current")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("51–100")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.5))
                                Spacer()
                            }
                            .padding(.top, 24)
                            .padding(.bottom, 8)
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.06, green: 0.06, blue: 0.12), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func packHeader(title: String, subtitle: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

struct LevelCell: View {
    let level: LevelData
    let stars: Int
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text("\(level.id)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(isUnlocked ? .white : .white.opacity(0.3))

            if stars > 0 {
                HStack(spacing: 1) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.system(size: 8))
                            .foregroundColor(i < stars ? .yellow : .white.opacity(0.2))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isUnlocked ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(isUnlocked ? 0.12 : 0.05), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        LevelSelectView()
    }
}
