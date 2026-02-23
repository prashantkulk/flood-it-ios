import SwiftUI

/// Entry point for the daily challenge. If already completed today, shows the result.
/// Otherwise, launches GameView in daily challenge mode.
struct DailyChallengeEntryView: View {
    @ObservedObject private var progress = ProgressStore.shared
    @Environment(\.dismiss) private var dismiss

    private let today = Date()
    private var challengeNumber: Int { DailyChallenge.challengeNumber(for: today) }
    private var dateString: String { DailyChallenge.dateString(for: today) }

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.12)
                .ignoresSafeArea()

            if let result = progress.dailyResult(for: dateString) {
                // Already completed — show result
                completedView(result: result)
            } else {
                // Not yet completed — launch game
                GameView(dailyChallengeDate: today)
            }
        }
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private func completedView(result: DailyResult) -> some View {
        VStack(spacing: 24) {
            Text("Daily Challenge #\(challengeNumber)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Completed!")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            HStack(spacing: 4) {
                Text("\(result.movesUsed)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("/ \(result.moveBudget) moves")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < result.starsEarned ? "star.fill" : "star")
                        .font(.system(size: 28))
                        .foregroundColor(index < result.starsEarned ? .yellow : .white.opacity(0.3))
                }
            }

            Button(action: { dismiss() }) {
                Text("Back")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.06, green: 0.06, blue: 0.12))
                    .padding(.horizontal, 48)
                    .padding(.vertical, 16)
                    .background(.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 16)
        }
    }
}
