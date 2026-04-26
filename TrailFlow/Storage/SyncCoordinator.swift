import Foundation
import SwiftData
import HealthKit

@Observable
final class SyncCoordinator {
    enum State: Equatable {
        case idle
        case syncing
        case error(String)
    }

    var state: State = .idle
    var lastSyncedAt: Date?

    private let hk = HealthKitService.shared
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    @MainActor
    func sync(startDate: Date) async {
        guard state != .syncing else { return }
        state = .syncing
        defer { state = .idle }

        do {
            let context = modelContainer.mainContext
            // Determine watermark: latest stored startDate, or user start date.
            let descriptor = FetchDescriptor<Run>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
            let existing = (try? context.fetch(descriptor)) ?? []
            let existingIds = Set(existing.map { $0.id })
            let watermark = max(existing.first?.startDate ?? .distantPast, startDate)

            let workouts = try await hk.fetchRunningWorkouts(since: watermark)
            for w in workouts {
                if existingIds.contains(w.uuid) { continue }
                let run = Run(
                    id: w.uuid,
                    startDate: w.startDate,
                    endDate: w.endDate,
                    distanceMetres: hk.distanceMetres(for: w),
                    durationSeconds: w.duration,
                    elevationGainMetres: hk.elevationGainMetres(for: w),
                    avgHeartRate: hk.averageHeartRate(for: w),
                    maxHeartRate: hk.maxHeartRate(for: w)
                )
                context.insert(run)
            }
            try context.save()
            lastSyncedAt = Date()
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
