import Foundation

enum AppEnvironment {
    case debug
    case release

    struct PlannerConfiguration: Equatable {
        let baseURLString: String
        let appSharedSecret: String
        let baseURLSource: String
    }

    static let current: AppEnvironment = {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
    }()

    private enum Key {
        static let apiBaseURL = "CITYSCOUT_API_BASE_URL"
        static let simulatorAPIBaseURL = "CITYSCOUT_SIMULATOR_API_BASE_URL"
        static let deviceAPIBaseURL = "CITYSCOUT_DEVICE_API_BASE_URL"
        static let appSharedSecret = "CITYSCOUT_APP_SHARED_SECRET"
    }

    var plannerConfiguration: PlannerConfiguration {
        Self.resolvePlannerConfiguration(
            infoDictionary: Bundle.main.infoDictionary ?? [:],
            environment: ProcessInfo.processInfo.environment,
            isSimulator: Self.isRunningInSimulator,
            isDebugBuild: isDebugBuild
        )
    }

    var baseURLString: String {
        plannerConfiguration.baseURLString
    }

    var appSharedSecret: String {
        plannerConfiguration.appSharedSecret
    }

    #if DEBUG
    var debugPlannerSummary: String {
        let configuration = plannerConfiguration
        let displayURL = configuration.baseURLString.isEmpty ? "unconfigured" : configuration.baseURLString
        let secretStatus = configuration.appSharedSecret.isEmpty ? "secret missing" : "secret configured"
        return "\(displayURL) (\(configuration.baseURLSource), \(secretStatus))"
    }
    #endif

    static func resolvePlannerConfiguration(
        infoDictionary: [String: Any],
        environment: [String: String],
        isSimulator: Bool,
        isDebugBuild: Bool
    ) -> PlannerConfiguration {
        let universalBaseURL = resolvedValue(
            key: Key.apiBaseURL,
            infoDictionary: infoDictionary,
            environment: environment
        )

        let runtimeSpecificKey = isSimulator ? Key.simulatorAPIBaseURL : Key.deviceAPIBaseURL
        let runtimeBaseURL = resolvedValue(
            key: runtimeSpecificKey,
            infoDictionary: infoDictionary,
            environment: environment
        )

        let fallbackBaseURL = isDebugBuild && isSimulator ? "http://127.0.0.1:8000" : ""
        let resolvedBaseURL: String
        let baseURLSource: String

        if let universalBaseURL {
            resolvedBaseURL = universalBaseURL
            baseURLSource = Key.apiBaseURL
        } else if let runtimeBaseURL {
            resolvedBaseURL = runtimeBaseURL
            baseURLSource = runtimeSpecificKey
        } else {
            resolvedBaseURL = fallbackBaseURL
            baseURLSource = fallbackBaseURL.isEmpty ? "unconfigured" : "simulator fallback"
        }

        let appSharedSecret = resolvedValue(
            key: Key.appSharedSecret,
            infoDictionary: infoDictionary,
            environment: environment
        ) ?? ""

        return PlannerConfiguration(
            baseURLString: resolvedBaseURL,
            appSharedSecret: appSharedSecret,
            baseURLSource: baseURLSource
        )
    }

    private var isDebugBuild: Bool {
        switch self {
        case .debug:
            return true
        case .release:
            return false
        }
    }

    private static var isRunningInSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    private static func resolvedValue(
        key: String,
        infoDictionary: [String: Any],
        environment: [String: String]
    ) -> String? {
        if let environmentValue = environment[key] {
            let trimmed = environmentValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty == false {
                return trimmed
            }
        }

        if let infoValue = infoDictionary[key] as? String {
            let trimmed = infoValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty == false {
                return trimmed
            }
        }

        return nil
    }

    // NOTE: This app must not ship with embedded secrets. If private backend access is still required,
    // configure it outside the committed codebase and treat that as a temporary bridge, not production auth.
}
