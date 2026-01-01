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
        .onKeyPress(.upArrow) {
            goalsViewModel.selectPreviousGoal()
            return .handled
        }
        .onKeyPress(.downArrow) {
            goalsViewModel.selectNextGoal()
            return .handled
        }
        .onKeyPress(.return) {
            goalsViewModel.toggleSelectedGoal()
            return .handled
        }
    }
}
