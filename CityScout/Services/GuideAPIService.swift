import Foundation

struct GuideAPIService {
    private static let guidePath = "/guide/message"

    struct GuideRequest: Codable {
        let destination: String
        let message: String
        let context: [String]
    }

    struct GuideResponse: Codable {
        let destination: String
        let reply: String
        let suggestedPrompts: [String]

        enum CodingKeys: String, CodingKey {
            case destination
            case reply
            case suggestedPrompts = "suggested_prompts"
        }
    }

    enum ServiceError: LocalizedError {
        case invalidBaseURL
        case requestEncodingFailed
        case invalidResponse
        case unauthorized
        case forbidden
        case rateLimited
        case serverError(statusCode: Int)
        case transportError
        case emptyResponse
        case decodingFailed

        var errorDescription: String? {
            switch self {
            case .invalidBaseURL:
                return "The guide service URL is invalid."
            case .requestEncodingFailed:
                return "The guide request could not be prepared."
            case .invalidResponse:
                return "The guide service returned an unexpected response."
            case .unauthorized:
                return "Guide service unavailable. Please try again."
            case .forbidden:
                return "The guide service rejected this request."
            case .rateLimited:
                return "The guide is busy right now. Please try again in a moment."
            case .serverError(let statusCode):
                return "The guide service returned an error (\(statusCode))."
            case .transportError:
                return "The guide service is unavailable right now."
            case .emptyResponse:
                return "The guide service returned an empty response."
            case .decodingFailed:
                return "The guide response could not be read."
            }
        }
    }

    private let environment: AppEnvironment
    private let session: URLSession

    init(environment: AppEnvironment = .current, session: URLSession = .shared) {
        self.environment = environment
        self.session = session
    }

    func sendMessage(destination: String, message: String, context: [String] = []) async throws -> GuideResponse {
        let request = try makeRequest(destination: destination, message: message, context: context)
        let data = try await performRequest(request)
        return try decodeResponse(from: data)
    }

    private func makeRequest(destination: String, message: String, context: [String]) throws -> URLRequest {
        let url = try endpointURL()
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(environment.appSharedSecret, forHTTPHeaderField: "X-CityScout-App-Secret")

        do {
            request.httpBody = try JSONEncoder().encode(
                GuideRequest(destination: destination, message: message, context: context)
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
        components.path = normalizedPath.isEmpty ? Self.guidePath : "/\(normalizedPath)\(Self.guidePath)"

        guard let url = components.url else {
            throw ServiceError.invalidBaseURL
        }

        return url
    }

    private func performRequest(_ request: URLRequest) async throws -> Data {
        let responseData: Data
        let response: URLResponse

        do {
            (responseData, response) = try await session.data(for: request)
        } catch {
            throw ServiceError.transportError
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200 ..< 300:
            guard responseData.isEmpty == false else {
                throw ServiceError.emptyResponse
            }
            return responseData
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

    private func decodeResponse(from data: Data) throws -> GuideResponse {
        do {
            return try JSONDecoder().decode(GuideResponse.self, from: data)
        } catch {
            throw ServiceError.decodingFailed
        }
    }
}
