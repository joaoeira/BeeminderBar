import SwiftUI

struct GoalListView: View {
    @EnvironmentObject var goalsViewModel: GoalsViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(goalsViewModel.sortedGoals) { goal in
                    GoalRowView(
                        goal: goal,
                        isExpanded: goalsViewModel.selectedGoalId == goal.id
                    )
                    .onTapGesture {
                        goalsViewModel.toggleGoalExpanded(goal)
                    }
                }
            }
            .padding()
        }
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.upArrow) {
            goalsViewModel.selectPreviousGoal()
            return .handled
        }
        .onKeyPress(.downArrow) {
            goalsViewModel.selectNextGoal()
            return .handled
        }
        .onKeyPress { press in
            guard press.key == .return else { return .ignored }
            // Cmd+Enter with a value in input submits instead of toggling
            if press.modifiers.contains(.command),
               let goalId = goalsViewModel.selectedGoalId,
               let goal = goalsViewModel.sortedGoals.first(where: { $0.id == goalId }),
               let value = goalsViewModel.datapointInputValues[goalId],
               !value.isEmpty {
                Task { await goalsViewModel.addDatapoint(to: goal) }
                return .handled
            }
            goalsViewModel.toggleSelectedGoal()
            return .handled
        }
    }
}
