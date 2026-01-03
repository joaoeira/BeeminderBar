import Combine
import SwiftUI

@MainActor
class GoalsViewModel: ObservableObject {
    // MARK: - Published State
    @Published var goals: [Goal] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedGoalId: String?
    @Published var datapointInputValues: [String: String] = [:]  // goalId -> input text
    @Published var submittingGoalIds: Set<String> = []
    @Published var updatingGoalIds: Set<String> = []  // goals waiting for Beeminder to process update

    // MARK: - Services
    private let api = BeeminderAPI()
    let refreshService = GoalRefreshService()

    // MARK: - Computed Properties

    var emergencyCount: Int {
        goals.filter { $0.isEmergency }.count
    }

    var sortedGoals: [Goal] {
        goals.sorted { $0.safebuf < $1.safebuf }
    }

    // MARK: - Initialization

    init() {
        refreshService.onRefreshNeeded = { [weak self] in
            await self?.fetchGoals()
        }
    }

    // MARK: - Actions

    func fetchGoals() async {
        guard let token = KeychainService.load(.accessToken) else { return }

        isLoading = true
        error = nil

        do {
            goals = try await api.fetchGoals(token: token)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func addDatapoint(to goal: Goal) async {
        guard let token = KeychainService.load(.accessToken),
              let inputText = datapointInputValues[goal.id],
              let value = Double(inputText) else { return }

        submittingGoalIds.insert(goal.id)

        // Capture the current goal state before submission
        let goalBeforeUpdate = goal

        do {
            _ = try await api.createDatapoint(
                goalSlug: goal.slug,
                value: value,
                token: token
            )

            datapointInputValues[goal.id] = nil

            // Move from submitting to updating state
            submittingGoalIds.remove(goal.id)
            updatingGoalIds.insert(goal.id)

            // Start retry loop with exponential backoff
            await retryFetchUntilUpdated(goalId: goal.id, previousGoal: goalBeforeUpdate)
        } catch {
            self.error = error
            submittingGoalIds.remove(goal.id)
        }
    }

    private func retryFetchUntilUpdated(goalId: String, previousGoal: Goal) async {
        // Retry intervals: 5s, 15s, 30s, 1min
        let retryIntervals: [UInt64] = [5, 15, 30, 60]

        for interval in retryIntervals {
            // Wait for the specified interval
            try? await Task.sleep(nanoseconds: interval * 1_000_000_000)

            // Fetch updated goals
            await fetchGoals()

            // Check if the goal has been updated
            if let updatedGoal = goals.first(where: { $0.id == goalId }),
               hasGoalBeenUpdated(previous: previousGoal, current: updatedGoal) {
                // Update detected, stop retrying
                updatingGoalIds.remove(goalId)
                return
            }
        }

        // Final fetch after all retries
        updatingGoalIds.remove(goalId)
    }

    private func hasGoalBeenUpdated(previous: Goal, current: Goal) -> Bool {
        // Compare key fields that should change after a datapoint submission
        // Check if curval has changed
        if previous.curval != current.curval {
            return true
        }

        // Check if delta (distance from centerline) has changed
        if previous.delta != current.delta {
            return true
        }

        // Check if safety buffer has changed
        if previous.safebuf != current.safebuf {
            return true
        }

        // Check if updatedAt timestamp has changed
        if previous.updatedAt != current.updatedAt {
            return true
        }

        return false
    }

    func toggleGoalExpanded(_ goal: Goal) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedGoalId == goal.id {
                selectedGoalId = nil
            } else {
                selectedGoalId = goal.id
            }
        }
    }

    func selectNextGoal() {
        guard !sortedGoals.isEmpty else { return }
        guard let selectedId = selectedGoalId,
              let index = sortedGoals.firstIndex(where: { $0.id == selectedId }) else {
            selectedGoalId = sortedGoals.first?.id
            return
        }

        let nextIndex = min(sortedGoals.count - 1, index + 1)
        selectedGoalId = sortedGoals[nextIndex].id
    }

    func selectPreviousGoal() {
        guard !sortedGoals.isEmpty else { return }
        guard let selectedId = selectedGoalId,
              let index = sortedGoals.firstIndex(where: { $0.id == selectedId }) else {
            selectedGoalId = sortedGoals.last?.id
            return
        }

        let prevIndex = max(0, index - 1)
        selectedGoalId = sortedGoals[prevIndex].id
    }

    func toggleSelectedGoal() {
        guard let selectedId = selectedGoalId,
              let goal = sortedGoals.first(where: { $0.id == selectedId }) else {
            selectedGoalId = sortedGoals.first?.id
            return
        }

        toggleGoalExpanded(goal)
    }

    func startPolling() {
        refreshService.startPolling()
    }

    func stopPolling() {
        refreshService.stopPolling()
    }
}
