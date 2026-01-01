import Foundation
import SwiftUI

struct Goal: Codable, Identifiable {
    let id: String
    let slug: String
    let title: String
    let goalType: String

    // Urgency/timing
    let losedate: Int           // Unix timestamp of derailment
    let safebuf: Int            // Days of safety buffer
    let limsum: String          // Human-readable: "+2 due in 1 day"

    // Progress
    let delta: Double           // Distance from centerline
    let todayta: Bool           // Has data today?
    let curval: Double?         // Current value
    let curday: Int?            // Current day

    // Visual
    let graphUrl: String
    let thumbUrl: String
    let svgUrl: String?

    // Stakes
    let pledge: Double          // Current pledge amount

    // Units
    let gunits: String          // Goal units (e.g., "hours", "pages")
    let rate: Double?           // Rate (e.g., 1.5 per day)
    let runits: String          // Rate units (d, w, m, y)

    // Metadata
    let updatedAt: Int?

    enum CodingKeys: String, CodingKey {
        case id, slug, title, losedate, safebuf, limsum
        case delta, todayta, curval, curday
        case pledge, gunits, rate, runits
        case goalType = "goal_type"
        case graphUrl = "graph_url"
        case thumbUrl = "thumb_url"
        case svgUrl = "svg_url"
        case updatedAt = "updated_at"
    }
}

// MARK: - Computed Properties
extension Goal {
    /// Color based on urgency
    var urgencyColor: Color {
        switch safebuf {
        case ..<1:  return .red      // Beemergency!
        case 1:     return .orange   // Due tomorrow
        case 2:     return .blue     // Due in 2 days
        case 3..<7: return .green    // Safe for now
        default:    return .gray     // Very safe
        }
    }

    /// Human-readable time until derailment
    var deadlineText: String {
        let date = Date(timeIntervalSince1970: TimeInterval(losedate))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Is this an emergency?
    var isEmergency: Bool {
        safebuf < 1
    }

    /// Formatted pledge amount
    var pledgeText: String? {
        guard pledge > 0 else { return nil }
        return "$\(Int(pledge))"
    }

    /// Rate description (e.g., "1.5/day")
    var rateText: String? {
        guard let rate = rate else { return nil }
        let unitMap = ["d": "day", "w": "week", "m": "month", "y": "year"]
        let unit = unitMap[runits] ?? runits
        return "\(rate.formatted())/\(unit)"
    }
}
