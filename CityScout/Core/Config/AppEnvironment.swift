import Foundation

enum AppEnvironment {
    case localDevelopment
    case staging

    static let current: AppEnvironment = .localDevelopment

    var baseURLString: String {
        switch self {
        case .localDevelopment:
            return "http://127.0.0.1:8000"
        case .staging:
            return "https://staging-api.cityscout.example"
        }
    }

    // TODO: Use an HTTPS production backend before broader external testing.
    // TODO: Replace this compile-time default with a TestFlight-safe backend configuration path.
}
