import Foundation

actor BeeminderAPI {
    private let baseURL = Constants.beeminderBaseURL
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Goals

    func fetchGoals(token: String) async throws -> [Goal] {
        let url = URL(string: "\(baseURL)/users/me/goals.json?access_token=\(token)")!
        let (data, response) = try await session.data(from: url)

        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode([Goal].self, from: data)
    }

    func fetchGoal(slug: String, token: String) async throws -> Goal {
        let url = URL(string: "\(baseURL)/users/me/goals/\(slug).json?access_token=\(token)")!
        let (data, response) = try await session.data(from: url)

        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode(Goal.self, from: data)
    }

    // MARK: - Datapoints

    func createDatapoint(
        goalSlug: String,
        value: Double,
        comment: String? = nil,
        token: String
    ) async throws -> Datapoint {
        let url = URL(string: "\(baseURL)/users/me/goals/\(goalSlug)/datapoints.json")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = CreateDatapointRequest(
            value: value,
            comment: comment,
            requestid: UUID().uuidString,
            authToken: token
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode(Datapoint.self, from: data)
    }

    func fetchDatapoints(
        goalSlug: String,
        count: Int = 10,
        token: String
    ) async throws -> [Datapoint] {
        var components = URLComponents(string: "\(baseURL)/users/me/goals/\(goalSlug)/datapoints.json")!
        components.queryItems = [
            URLQueryItem(name: "access_token", value: token),
            URLQueryItem(name: "count", value: String(count)),
            URLQueryItem(name: "sort", value: "timestamp")
        ]

        let (data, response) = try await session.data(from: components.url!)

        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode([Datapoint].self, from: data)
    }

    // MARK: - User

    func fetchUser(token: String) async throws -> User {
        let url = URL(string: "\(baseURL)/users/me.json?access_token=\(token)")!
        let (data, response) = try await session.data(from: url)

        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode(User.self, from: data)
    }

    // MARK: - Helpers

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    enum APIError: LocalizedError {
        case invalidResponse
        case unauthorized
        case notFound
        case rateLimited
        case serverError(Int)

        var errorDescription: String? {
            switch self {
            case .invalidResponse: return "Invalid response from server"
            case .unauthorized: return "Please log in again"
            case .notFound: return "Goal not found"
            case .rateLimited: return "Too many requests, please wait"
            case .serverError(let code): return "Server error (\(code))"
            }
        }
    }
}
