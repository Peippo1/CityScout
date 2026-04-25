import Foundation

enum AppEnvironment {
    case debug
    case release

    struct PlannerConfiguration: Equatable {
        let baseURLString: String
        let baseURLSource: String
        let appSecret: String
        let appSecretSource: String
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
        static let appSecret = "CITYSCOUT_APP_SECRET"
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

    var appSecret: String {
        plannerConfiguration.appSecret
    }

    #if DEBUG
    var debugPlannerSummary: String {
        let configuration = plannerConfiguration
        let displayURL = configuration.baseURLString.isEmpty ? "unconfigured" : configuration.baseURLString
        let displaySecret = configuration.appSecret.isEmpty ? "unconfigured" : "configured"
        return "\(displayURL) (\(configuration.baseURLSource)); app secret \(displaySecret) (\(configuration.appSecretSource))"
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

        let resolvedAppSecret: String
        let appSecretSource: String
        if let secret = resolvedValue(
            key: Key.appSecret,
            infoDictionary: infoDictionary,
            environment: environment
        ) {
            resolvedAppSecret = secret
            appSecretSource = Key.appSecret
        } else {
            resolvedAppSecret = isDebugBuild ? "dev-secret" : ""
            appSecretSource = isDebugBuild ? "debug fallback" : "unconfigured"
        }

        return PlannerConfiguration(
            baseURLString: resolvedBaseURL,
            baseURLSource: baseURLSource,
            appSecret: resolvedAppSecret,
            appSecretSource: appSecretSource
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
}
