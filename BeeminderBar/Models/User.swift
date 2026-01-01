import Foundation

struct User: Codable {
    let username: String
    let timezone: String
    let updatedAt: Int
    let goals: [String]?       // Goal slugs (if requested)

    enum CodingKeys: String, CodingKey {
        case username, timezone, goals
        case updatedAt = "updated_at"
    }
}
