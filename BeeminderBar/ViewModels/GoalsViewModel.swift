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

        isLoading = goals.isEmpty
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

        do {
            _ = try await api.createDatapoint(
                goalSlug: goal.slug,
                value: value,
                token: token
            )

            datapointInputValues[goal.id] = nil
            await fetchGoals()
        } catch {
            self.error = error
        }

        submittingGoalIds.remove(goal.id)
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
