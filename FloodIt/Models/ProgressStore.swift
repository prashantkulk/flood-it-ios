import Foundation

/// Persists player progress: best star rating per level and total stars.
/// Uses UserDefaults with JSON-encoded Codable data.
class ProgressStore: ObservableObject {
    static let shared = ProgressStore()

    private static let storageKey = "progress_levelStars"

    /// Best star rating per level (level ID → stars 0-3)
    @Published private(set) var levelStars: [Int: Int]

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([Int: Int].self, from: data) {
            self.levelStars = decoded
        } else {
            self.levelStars = [:]
        }
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
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(levelStars) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
