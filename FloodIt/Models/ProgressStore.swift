import Foundation

/// Result of a completed daily challenge.
struct DailyResult: Codable {
    let dateString: String
    let movesUsed: Int
    let moveBudget: Int
    let starsEarned: Int
    let colorsUsed: [Int] // GameColor raw values of first moves
}

/// Persists player progress: best star rating per level, total stars, and daily streak.
/// Uses UserDefaults with JSON-encoded Codable data.
class ProgressStore: ObservableObject {
    static let shared = ProgressStore()

    private static let starsKey = "progress_levelStars"
    private static let scoresKey = "progress_levelScores"
    private static let lastPlayDateKey = "progress_lastPlayDate"
    private static let currentStreakKey = "progress_currentStreak"
    private static let longestStreakKey = "progress_longestStreak"
    private static let dailyResultsKey = "progress_dailyResults"

    /// Best star rating per level (level ID → stars 0-3)
    @Published private(set) var levelStars: [Int: Int]

    /// Best score per level (level ID → score)
    @Published private(set) var levelScores: [Int: Int]

    /// Daily play streak
    @Published private(set) var currentStreak: Int
    @Published private(set) var longestStreak: Int
    private var lastPlayDate: Date?

    /// Daily challenge results keyed by date string (YYYY-MM-DD)
    @Published private(set) var dailyResults: [String: DailyResult]

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.starsKey),
           let decoded = try? JSONDecoder().decode([Int: Int].self, from: data) {
            self.levelStars = decoded
        } else {
            self.levelStars = [:]
        }

        if let data = UserDefaults.standard.data(forKey: Self.scoresKey),
           let decoded = try? JSONDecoder().decode([Int: Int].self, from: data) {
            self.levelScores = decoded
        } else {
            self.levelScores = [:]
        }

        if let data = UserDefaults.standard.data(forKey: Self.dailyResultsKey),
           let decoded = try? JSONDecoder().decode([String: DailyResult].self, from: data) {
            self.dailyResults = decoded
        } else {
            self.dailyResults = [:]
        }

        self.currentStreak = UserDefaults.standard.integer(forKey: Self.currentStreakKey)
        self.longestStreak = UserDefaults.standard.integer(forKey: Self.longestStreakKey)

        if let timestamp = UserDefaults.standard.object(forKey: Self.lastPlayDateKey) as? Double {
            self.lastPlayDate = Date(timeIntervalSince1970: timestamp)
        }

        // Check if streak is still valid (not skipped a day)
        validateStreak()
    }

    /// Returns the best star rating for a level (0 if never completed).
    func stars(for levelId: Int) -> Int {
        levelStars[levelId] ?? 0
    }

    /// Total stars earned across all levels.
    var totalStars: Int {
        levelStars.values.reduce(0, +)
    }

    /// Update star rating for a level if the new rating is better than saved.
    func updateStars(for levelId: Int, stars: Int) {
        let current = self.stars(for: levelId)
        guard stars > current else { return }
        levelStars[levelId] = stars
        saveStars()
    }

    /// Returns the best score for a level (0 if never completed).
    func bestScore(for levelId: Int) -> Int {
        levelScores[levelId] ?? 0
    }

    /// Update best score for a level. Returns true if this is a new best.
    @discardableResult
    func updateScore(for levelId: Int, score: Int) -> Bool {
        let current = bestScore(for: levelId)
        guard score > current else { return false }
        levelScores[levelId] = score
        saveScores()
        return true
    }

    /// Record that the player played today. Call on level completion.
    func recordPlay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let last = lastPlayDate {
            let lastDay = calendar.startOfDay(for: last)
            if lastDay == today {
                // Already played today, no change
                return
            }
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if lastDay == calendar.startOfDay(for: yesterday) {
                // Consecutive day
                currentStreak += 1
            } else {
                // Skipped a day, reset
                currentStreak = 1
            }
        } else {
            // First play ever
            currentStreak = 1
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        lastPlayDate = today
        saveStreak()
    }

    private func validateStreak() {
        guard let last = lastPlayDate else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: last)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // If last play was before yesterday, streak is broken
        if lastDay < calendar.startOfDay(for: yesterday) {
            currentStreak = 0
            saveStreak()
        }
    }

    // MARK: - Daily Challenge

    /// Returns the daily result for a given date string, or nil if not completed.
    func dailyResult(for dateString: String) -> DailyResult? {
        dailyResults[dateString]
    }

    /// Records a completed daily challenge.
    func saveDailyResult(_ result: DailyResult) {
        dailyResults[result.dateString] = result
        saveDailyResults()
    }

    private func saveDailyResults() {
        if let data = try? JSONEncoder().encode(dailyResults) {
            UserDefaults.standard.set(data, forKey: Self.dailyResultsKey)
        }
    }

    private func saveScores() {
        if let data = try? JSONEncoder().encode(levelScores) {
            UserDefaults.standard.set(data, forKey: Self.scoresKey)
        }
    }

    private func saveStars() {
        if let data = try? JSONEncoder().encode(levelStars) {
            UserDefaults.standard.set(data, forKey: Self.starsKey)
        }
    }

    private func saveStreak() {
        UserDefaults.standard.set(currentStreak, forKey: Self.currentStreakKey)
        UserDefaults.standard.set(longestStreak, forKey: Self.longestStreakKey)
        if let date = lastPlayDate {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Self.lastPlayDateKey)
        }
    }
}
