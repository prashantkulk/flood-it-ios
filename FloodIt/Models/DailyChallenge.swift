import Foundation

/// Generates a deterministic daily challenge board from today's date.
/// All players get the same board on the same day.
struct DailyChallenge {
    /// Fixed epoch for daily challenge numbering (January 1, 2026).
    static let epoch: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        return Calendar.current.date(from: components)!
    }()

    /// The challenge number (days since epoch). Day 0 = Jan 1 2026.
    static func challengeNumber(for date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: epoch)
        let day = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: day).day ?? 0
    }

    /// Date string in YYYY-MM-DD format for seed generation.
    static func dateString(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }

    /// Generates a deterministic UInt64 seed from a date string using FNV-1a hash.
    static func seed(for date: Date = Date()) -> UInt64 {
        let str = dateString(for: date)
        return fnv1aHash(str)
    }

    /// Generates today's daily challenge board (9x9, 5 colors).
    static func generateBoard(for date: Date = Date()) -> FloodBoard {
        let boardSeed = seed(for: date)
        return FloodBoard.generateBoard(size: 9, colors: GameColor.allCases, seed: boardSeed)
    }

    /// Move budget for daily challenges: optimal + 4 (moderate difficulty).
    static func moveBudget(for date: Date = Date()) -> Int {
        let board = generateBoard(for: date)
        let optimal = FloodSolver.solveMoveCount(board: board)
        return optimal + 4
    }

    // MARK: - FNV-1a Hash

    private static func fnv1aHash(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325 // FNV offset basis
        let prime: UInt64 = 0x100000001b3       // FNV prime
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= prime
        }
        return hash
    }
}
