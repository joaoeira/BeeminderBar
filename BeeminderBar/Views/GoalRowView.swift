import SwiftUI

struct GoalRowView: View {
    let goal: Goal
    let isExpanded: Bool

    @EnvironmentObject var goalsViewModel: GoalsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            mainRow

            if isExpanded {
                GoalDetailView(goal: goal)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(goal.isEmergency ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }

    private var mainRow: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(goal.urgencyColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(goal.title.isEmpty ? goal.slug : goal.title)
                        .font(.system(.body, weight: .medium))
                        .foregroundColor(Color(nsColor: .labelColor))
                        .lineLimit(1)

                    if goal.todayta {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                Text(goal.limsum)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(goal.deadlineText)
                    .font(.caption)
                    .foregroundColor(goal.isEmergency ? .red : .secondary)

                if let pledgeText = goal.pledgeText {
                    Text(pledgeText)
                        .font(.caption2)
                        .foregroundColor(.orange.opacity(0.8))
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
        .contentShape(Rectangle())
    }
}
