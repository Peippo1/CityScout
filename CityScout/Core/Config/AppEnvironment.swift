import Foundation

enum AppEnvironment {
    case debug
    case release

    struct PlannerConfiguration: Equatable {
        let baseURLString: String
        let baseURLSource: String
        let appSharedSecret: String
        let appSharedSecretSource: String
    }

    static let current: AppEnvironment = {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
    }()

    private static var isRunningInSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    private static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    private enum Key {
        static let apiBaseURL = "CITYSCOUT_API_BASE_URL"
        static let simulatorAPIBaseURL = "CITYSCOUT_SIMULATOR_API_BASE_URL"
        static let deviceAPIBaseURL = "CITYSCOUT_DEVICE_API_BASE_URL"
        static let appSharedSecret = "APP_SHARED_SECRET"
    }

    var plannerConfiguration: PlannerConfiguration {
        Self.resolvePlannerConfiguration(
            infoDictionary: Bundle.main.infoDictionary ?? [:],
            environment: ProcessInfo.processInfo.environment,
            isSimulator: Self.isRunningInSimulator,
            isDebugBuild: Self.isDebugBuild
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
        let displaySecret = configuration.appSharedSecret.isEmpty ? "unconfigured" : "configured"
        return "\(displayURL) (\(configuration.baseURLSource)); app shared secret \(displaySecret) (\(configuration.appSharedSecretSource))"
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

        let resolvedAppSharedSecret: String
        let appSharedSecretSource: String
        if let secret = resolvedValue(
            key: Key.appSharedSecret,
            infoDictionary: infoDictionary,
            environment: environment
        ) {
            resolvedAppSharedSecret = secret
            appSharedSecretSource = Key.appSharedSecret
        } else {
            resolvedAppSharedSecret = isDebugBuild ? "change_me_for_private_testing" : ""
            appSharedSecretSource = isDebugBuild ? "debug fallback" : "unconfigured"
        }

        return PlannerConfiguration(
            baseURLString: resolvedBaseURL,
            baseURLSource: baseURLSource,
            appSharedSecret: resolvedAppSharedSecret,
            appSharedSecretSource: appSharedSecretSource
        )
    }

    private static func resolvedValue(
        key: String,
        infoDictionary: [String: Any],
        environment: [String: String]
    ) -> String? {
        if let environmentValue = environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
           environmentValue.isEmpty == false {
            return environmentValue
        }

        if let infoValue = infoDictionary[key] as? String {
            let trimmed = infoValue.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        return nil
    }
}
