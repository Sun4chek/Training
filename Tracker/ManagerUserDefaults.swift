import Foundation

final class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private init() {}

    private let onboardingKey = "hasSeenOnboarding"

    /// Проверяем — видел ли пользователь онбординг
    var hasSeenOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: onboardingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: onboardingKey)
        }
    }

    /// Сбрасываем флаг (удобно для тестов)
    func resetOnboardingFlag() {
        UserDefaults.standard.removeObject(forKey: onboardingKey)
    }
}

