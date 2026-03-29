import Foundation

struct PlanAPIService {
    struct ItineraryRequest: Codable {
        let destination: String
        let prompt: String
        let preferences: [String]
        let savedPlaces: [String]

        enum CodingKeys: String, CodingKey {
            case destination
            case prompt
            case preferences
            case savedPlaces = "saved_places"
        }
    }

    struct ItineraryBlock: Codable {
        let title: String
        let activities: [String]
    }

    struct ItineraryResponse: Codable {
        let destination: String
        let morning: ItineraryBlock
        let afternoon: ItineraryBlock
        let evening: ItineraryBlock
        let notes: [String]
    }

    enum ServiceError: LocalizedError {
        case invalidBaseURL
        case invalidResponse
        case unauthorized
        case serverError(statusCode: Int)
        case backendUnavailable
        case decodingFailed

        var errorDescription: String? {
            switch self {
            case .invalidBaseURL:
                return "The planner service URL is invalid."
            case .invalidResponse:
                return "The planner service returned an unexpected response."
            case .unauthorized:
                return "Service unavailable. Please try again."
            case .serverError(let statusCode):
                return "The planner service returned an error (\(statusCode))."
            case .backendUnavailable:
                return "The planner service is unavailable right now."
            case .decodingFailed:
                return "The planner response could not be read."
            }
        }
    }

    // The iOS Simulator can often use 127.0.0.1 when the backend runs on the same Mac.
    // Real devices need a reachable host URL instead, such as a LAN IP, tunnel, or deployed backend.
    private let environment: AppEnvironment
    private let session: URLSession

    init(
        environment: AppEnvironment = AppEnvironment.current,
        session: URLSession = .shared
    ) {
        self.environment = environment
        self.session = session
    }

    var baseURLString: String { environment.baseURLString }

    // TODO: Keep backend selection aligned with the release channel before TestFlight distribution.

    func generateItinerary(
        destination: String,
        prompt: String,
        preferences: [String],
        savedPlaces: [String]
    ) async throws -> ItineraryResponse {
        let baseURLString = environment.baseURLString

        guard let url = URL(string: "\(baseURLString)/plan-itinerary") else {
            throw ServiceError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(environment.appSharedSecret, forHTTPHeaderField: "X-CityScout-App-Secret")
        request.timeoutInterval = 20
        request.httpBody = try JSONEncoder().encode(
            ItineraryRequest(
                destination: destination,
                prompt: prompt,
                preferences: preferences,
                savedPlaces: savedPlaces
            )
        )

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ServiceError.backendUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw ServiceError.unauthorized
        }

        guard 200 ..< 300 ~= httpResponse.statusCode else {
            throw ServiceError.serverError(statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(ItineraryResponse.self, from: data)
        } catch {
            throw ServiceError.decodingFailed
        }
    }
}
