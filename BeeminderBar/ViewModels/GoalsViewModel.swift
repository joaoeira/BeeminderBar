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

    func fetchGoals(showLoading: Bool = true) async {
        guard let token = KeychainService.load(.accessToken) else { return }

        if showLoading {
            isLoading = true
        }
        error = nil

        do {
            goals = try await api.fetchGoals(token: token)
        } catch {
            self.error = error
        }

        if showLoading {
            isLoading = false
        }
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
            await retryFetchUntilUpdated(goalId: goal.id, previousGoal: goalBeforeUpdate, submittedValue: value)
        } catch {
            self.error = error
            submittingGoalIds.remove(goal.id)
        }
    }

    private func retryFetchUntilUpdated(goalId: String, previousGoal: Goal, submittedValue: Double) async {
        // Immediate fetch - Beeminder might have already processed the update
        await fetchGoals(showLoading: false)
        if let updatedGoal = goals.first(where: { $0.id == goalId }),
           hasGoalBeenUpdated(previous: previousGoal, current: updatedGoal, submittedValue: submittedValue) {
            updatingGoalIds.remove(goalId)
            return
        }

        // Retry intervals: 5s, 15s, 30s, 1min
        let retryIntervals: [UInt64] = [5, 15, 30, 60]

        for interval in retryIntervals {
            do {
                try await Task.sleep(nanoseconds: interval * 1_000_000_000)
            } catch {
                // Task was cancelled, clean up and exit
                updatingGoalIds.remove(goalId)
                return
            }

            // Fetch updated goals (silent to avoid spinner flashing)
            await fetchGoals(showLoading: false)

            // Check if the goal has been updated
            if let updatedGoal = goals.first(where: { $0.id == goalId }),
               hasGoalBeenUpdated(previous: previousGoal, current: updatedGoal, submittedValue: submittedValue) {
                // Update detected, stop retrying
                updatingGoalIds.remove(goalId)
                return
            }
        }

        // Final fetch after all retries to ensure we have latest data
        await fetchGoals(showLoading: false)
        updatingGoalIds.remove(goalId)
    }

    private func hasGoalBeenUpdated(previous: Goal, current: Goal, submittedValue: Double) -> Bool {
        // We verify that curval changed by approximately the submitted value to avoid
        // false positives from unrelated changes (background refresh, time-based safebuf drift).
        let expectedDelta = abs(submittedValue)
        let tolerance = max(0.01, expectedDelta * 0.01)

        // Check curval if available
        if let prevCurval = previous.curval, let currCurval = current.curval {
            let curvalDelta = currCurval - prevCurval

            // For most goal types, curval increases by the submitted value
            // Check if curval changed by approximately what we submitted
            if abs(curvalDelta - submittedValue) <= tolerance {
                return true
            }

            // Some goal types may compute curval differently, so also check delta/safebuf
            // but only if curval also moved meaningfully (not just noise)
            if abs(curvalDelta) >= expectedDelta * 0.5 {
                if previous.delta != current.delta || previous.safebuf != current.safebuf {
                    return true
                }
            }
        } else {
            // curval not available, fall back to checking delta/safebuf changes
            if previous.delta != current.delta || previous.safebuf != current.safebuf {
                return true
            }
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
