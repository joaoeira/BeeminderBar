import Foundation

struct Datapoint: Codable, Identifiable {
    let id: String
    let timestamp: Int
    let daystamp: String    // "20240115" format
    let value: Double
    let comment: String
    let requestid: String?

    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
}

struct CreateDatapointRequest: Encodable {
    let value: Double
    let comment: String?
    let requestid: String      // UUID for idempotency
    let authToken: String

    enum CodingKeys: String, CodingKey {
        case value, comment, requestid
        case authToken = "access_token"
    }
}
