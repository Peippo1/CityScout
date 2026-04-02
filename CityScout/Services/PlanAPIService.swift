import Foundation

struct PlanAPIService {
    private static let plannerPath = "/plan-itinerary"

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
        case requestEncodingFailed
        case invalidResponse
        case unauthorized
        case forbidden
        case rateLimited
        case serverError(statusCode: Int)
        case transportError(URLError?)
        case emptyResponse
        case decodingFailed

        var errorDescription: String? {
            switch self {
            case .invalidBaseURL:
                return "The planner service URL is invalid."
            case .requestEncodingFailed:
                return "The planner request could not be prepared."
            case .invalidResponse:
                return "The planner service returned an unexpected response."
            case .unauthorized:
                return "Service unavailable. Please try again."
            case .forbidden:
                return "The planner service rejected this request."
            case .rateLimited:
                return "The planner service is busy right now. Please try again in a moment."
            case .serverError(let statusCode):
                return "The planner service returned an error (\(statusCode))."
            case .transportError:
                return "The planner service is unavailable right now."
            case .emptyResponse:
                return "The planner service returned an empty response."
            case .decodingFailed:
                return "The planner response could not be read."
            }
        }
    }

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

    func generateItinerary(
        destination: String,
        prompt: String,
        preferences: [String],
        savedPlaces: [String]
    ) async throws -> ItineraryResponse {
        let request = try makeRequest(
            destination: destination,
            prompt: prompt,
            preferences: preferences,
            savedPlaces: savedPlaces
        )

        let data = try await performRequest(request)
        return try decodeResponse(from: data)
    }

    private func makeRequest(
        destination: String,
        prompt: String,
        preferences: [String],
        savedPlaces: [String]
    ) throws -> URLRequest {
        let url = try endpointURL()
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        do {
            request.httpBody = try JSONEncoder().encode(
                ItineraryRequest(
                    destination: destination,
                    prompt: prompt,
                    preferences: preferences,
                    savedPlaces: savedPlaces
                )
            )
        } catch {
            throw ServiceError.requestEncodingFailed
        }

        return request
    }

    private func endpointURL() throws -> URL {
        let baseURLString = environment.baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard baseURLString.isEmpty == false,
              var components = URLComponents(string: baseURLString) else {
            throw ServiceError.invalidBaseURL
        }

        let normalizedPath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = normalizedPath.isEmpty ? Self.plannerPath : "/\(normalizedPath)\(Self.plannerPath)"

        guard let url = components.url else {
            throw ServiceError.invalidBaseURL
        }

        return url
    }

    private func performRequest(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            debugLog("Planner request transport error code=\(urlError.code.rawValue)")
            throw ServiceError.transportError(urlError)
        } catch {
            debugLog("Planner request failed with non-URL transport error")
            throw ServiceError.transportError(nil)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200 ..< 300:
            guard data.isEmpty == false else {
                throw ServiceError.emptyResponse
            }
            return data
        case 401:
            throw ServiceError.unauthorized
        case 403:
            throw ServiceError.forbidden
        case 429:
            throw ServiceError.rateLimited
        default:
            throw ServiceError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    private func decodeResponse(from data: Data) throws -> ItineraryResponse {
        do {
            return try JSONDecoder().decode(ItineraryResponse.self, from: data)
        } catch {
            throw ServiceError.decodingFailed
        }
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("PlanAPIService: \(message)")
        print("PlanAPIService config: \(environment.debugPlannerSummary)")
        #endif
    }
}
