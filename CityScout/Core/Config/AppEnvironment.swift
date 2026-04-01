import Foundation

enum AppEnvironment {
    case localDevelopment
    case staging

    static let current: AppEnvironment = .localDevelopment

    private static let apiBaseURLInfoKey = "CITYSCOUT_API_BASE_URL"
    private static let appSharedSecretInfoKey = "CITYSCOUT_APP_SHARED_SECRET"
    private static let apiBaseURLEnvKey = "CITYSCOUT_API_BASE_URL"
    private static let appSharedSecretEnvKey = "CITYSCOUT_APP_SHARED_SECRET"

    var baseURLString: String {
        resolvedValue(
            infoKey: Self.apiBaseURLInfoKey,
            environmentKey: Self.apiBaseURLEnvKey,
            fallback: defaultBaseURLString
        )
    }

    var appSharedSecret: String {
        resolvedValue(
            infoKey: Self.appSharedSecretInfoKey,
            environmentKey: Self.appSharedSecretEnvKey,
            fallback: defaultAppSharedSecret
        )
    }

    private var defaultBaseURLString: String {
        switch self {
        case .localDevelopment:
            return "http://127.0.0.1:8000"
        case .staging:
            return "https://staging-api.cityscout.example"
        }
    }

    private var defaultAppSharedSecret: String {
        switch self {
        case .localDevelopment:
            // TODO: Replace with a stronger private-testing and release configuration path.
            return "change_me_for_private_testing"
        case .staging:
            // TODO: Replace with a stronger private-testing and release configuration path.
            return "change_me_for_private_testing"
        }
    }

    private func resolvedValue(infoKey: String, environmentKey: String, fallback: String) -> String {
        if let infoValue = Bundle.main.object(forInfoDictionaryKey: infoKey) as? String {
            let trimmed = infoValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty == false {
                return trimmed
            }
        }

        if let environmentValue = ProcessInfo.processInfo.environment[environmentKey] {
            let trimmed = environmentValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty == false {
                return trimmed
            }
        }

        return fallback
    }

    // TODO: Use an HTTPS backend before broader external testing.
    // TODO: Set build-configuration-specific Info.plist values for simulator, device, and release channels.
}
