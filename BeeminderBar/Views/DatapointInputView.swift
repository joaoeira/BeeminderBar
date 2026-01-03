import SwiftUI

struct DatapointInputView: View {
    let goal: Goal

    @EnvironmentObject var goalsViewModel: GoalsViewModel

    var body: some View {
        HStack {
            TextField(
                "Value (\(goal.gunits))",
                text: Binding(
                    get: { goalsViewModel.datapointInputValues[goal.id] ?? "" },
                    set: { goalsViewModel.datapointInputValues[goal.id] = $0 }
                )
            )
            .textFieldStyle(.roundedBorder)
            .disabled(
                goalsViewModel.submittingGoalIds.contains(goal.id) ||
                goalsViewModel.updatingGoalIds.contains(goal.id)
            )
            .onSubmit {
                Task { await goalsViewModel.addDatapoint(to: goal) }
            }

            Button {
                Task { await goalsViewModel.addDatapoint(to: goal) }
            } label: {
                if goalsViewModel.submittingGoalIds.contains(goal.id) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 20, height: 20)
                } else if goalsViewModel.updatingGoalIds.contains(goal.id) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .buttonStyle(.borderless)
            .disabled(
                goalsViewModel.datapointInputValues[goal.id]?.isEmpty ?? true ||
                goalsViewModel.submittingGoalIds.contains(goal.id) ||
                goalsViewModel.updatingGoalIds.contains(goal.id)
            )
        }
    }
}
