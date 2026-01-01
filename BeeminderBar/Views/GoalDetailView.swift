import AppKit
import SwiftUI

struct GoalDetailView: View {
    let goal: Goal

    @EnvironmentObject var goalsViewModel: GoalsViewModel
    @State private var showGraph = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .padding(.top, 8)

            graphSection

            DatapointInputView(goal: goal)

            actionButtons
        }
    }

    private var graphSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation { showGraph.toggle() }
            } label: {
                HStack {
                    Image(systemName: showGraph ? "chevron.down" : "chevron.right")
                        .font(.caption)
                    Text("Graph")
                        .font(.caption)
                    Spacer()
                }
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            if showGraph {
                AsyncImage(url: URL(string: goal.graphUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(4)
                    case .failure:
                        Text("Failed to load graph")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack {
            Button {
                let username = KeychainService.load(.username) ?? "me"
                if let url = URL(string: "https://www.beeminder.com/\(username)/\(goal.slug)") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label("Open in Browser", systemImage: "arrow.up.right.square")
                    .font(.caption)
            }
            .buttonStyle(.borderless)

            Spacer()

            if let rateText = goal.rateText {
                Text(rateText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
