import SwiftUI
import CoreLocation

struct RunRowView: View {
    @Environment(\.theme) private var theme
    let run: Run

    @State private var entry: RouteCache.Entry?
    @State private var loadFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("$")
                    .foregroundColor(theme.green)
                Text("run --date")
                    .foregroundColor(theme.fg)
                Text(run.isoDate)
                    .foregroundColor(theme.cyan)
            }
            .terminalFont(12)

            HStack(spacing: 8) {
                metric(run.formattedDistance, color: theme.fg)
                dot
                metric(run.formattedDuration, color: theme.fg)
                dot
                metric(run.formattedElevation, color: theme.orange)
            }
            .terminalFont(15, weight: .semibold)

            if let entry, entry.paceBuckets.count >= 2 {
                SparklineView(values: entry.paceBuckets)
            }
        }
        .terminalCard()
        .task(id: run.id) { await loadRoute() }
    }

    @ViewBuilder private var dot: some View {
        Text("·").foregroundColor(theme.comment)
    }

    private func metric(_ s: String, color: Color) -> some View {
        Text(s).foregroundColor(color)
    }

    private func loadRoute() async {
        do {
            let id = run.id
            if let cached = await RouteCache.shared.cached(id) {
                await MainActor.run { self.entry = cached }
                return
            }
            let result = try await RouteCache.shared.load(id: id) {
                let hk = HealthKitService.shared
                guard let w = try await hk.fetchWorkout(uuid: id) else { return [] }
                return try await hk.fetchRoute(for: w)
            }
            await MainActor.run { self.entry = result }
        } catch {
            print("[TrailFlow] loadRoute failed for \(run.id): \(error)")
            await MainActor.run { self.loadFailed = true }
        }
    }
}
