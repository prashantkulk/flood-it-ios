import UIKit

// MARK: - P12-T1 AdManager protocol and mock implementation

/// Protocol for ad management. Swap MockAdManager for a real AdMob implementation later.
protocol AdManager: AnyObject {
    /// Whether the user has purchased ad-free mode.
    var isAdFree: Bool { get set }

    /// Pre-load an interstitial ad.
    func loadInterstitial()
    /// Show an interstitial ad. Completion called when ad is dismissed (true) or failed (false).
    func showInterstitial(from viewController: UIViewController, completion: @escaping (Bool) -> Void)

    /// Pre-load a rewarded video ad.
    func loadRewardedVideo()
    /// Show a rewarded video. Completion called with true if reward earned, false otherwise.
    func showRewardedVideo(from viewController: UIViewController, completion: @escaping (Bool) -> Void)
}

/// Mock ad manager that simulates ad loading/showing with fake delays.
final class MockAdManager: AdManager {
    static let shared = MockAdManager()

    var isAdFree: Bool {
        get { UserDefaults.standard.bool(forKey: "adFree") }
        set { UserDefaults.standard.set(newValue, forKey: "adFree") }
    }

    private var interstitialReady = false
    private var rewardedVideoReady = false

    private init() {
        // Pre-load ads on init
        loadInterstitial()
        loadRewardedVideo()
    }

    func loadInterstitial() {
        interstitialReady = false
        // Simulate 1-second network load
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.interstitialReady = true
        }
    }

    func showInterstitial(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard !isAdFree else {
            completion(true)
            return
        }
        guard interstitialReady else {
            completion(false)
            return
        }
        interstitialReady = false
        // Simulate 2-second ad display
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            completion(true)
            self?.loadInterstitial() // Pre-load next one
        }
    }

    func loadRewardedVideo() {
        rewardedVideoReady = false
        // Simulate 1-second network load
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.rewardedVideoReady = true
        }
    }

    func showRewardedVideo(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard !isAdFree else {
            completion(true)
            return
        }
        guard rewardedVideoReady else {
            completion(false)
            return
        }
        rewardedVideoReady = false
        // Simulate 2-second rewarded video, then grant reward
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            completion(true)
            self?.loadRewardedVideo() // Pre-load next one
        }
    }
}

/// Shared ad manager instance. Replace MockAdManager with real AdMob implementation later.
let adManager: AdManager = MockAdManager.shared
