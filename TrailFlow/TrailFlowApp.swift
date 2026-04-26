import SwiftUI
import SwiftData

@main
struct TrailFlowApp: App {
    let container: ModelContainer
    @State private var settings = AppSettings.shared
    @State private var coordinator: SyncCoordinator

    init() {
        do {
            container = try ModelContainer(for: Run.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        _coordinator = State(initialValue: SyncCoordinator(modelContainer: container))
    }

    var body: some Scene {
        WindowGroup {
            RootView(settings: settings, coordinator: coordinator)
                .preferredColorScheme(.dark)
                .modelContainer(container)
        }
    }
}

struct RootView: View {
    @Environment(\.theme) private var theme
    let settings: AppSettings
    let coordinator: SyncCoordinator

    var body: some View {
        Group {
            if settings.hasOnboarded {
                RunListView(settings: settings, coordinator: coordinator)
            } else {
                FirstLaunchView(settings: settings) {
                    // onComplete: trigger first sync
                    Task { await coordinator.sync(startDate: settings.startDate) }
                }
            }
        }
        .tint(theme.cyan)
    }
}
