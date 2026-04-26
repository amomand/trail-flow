import SwiftUI
import SwiftData

struct RunListView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Run.startDate, order: .reverse) private var runs: [Run]

    let settings: AppSettings
    let coordinator: SyncCoordinator
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                theme.bg.ignoresSafeArea()
                if runs.isEmpty {
                    EmptyStateView(syncState: coordinator.state, onRetry: refresh)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(runs) { run in
                                NavigationLink {
                                    RunDetailView(run: run)
                                } label: {
                                    RunRowView(run: run)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                    .refreshable { await coordinator.sync(startDate: settings.startDate) }
                }
            }
            .navigationTitle("trail-flow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(theme.cyan)
                    }
                }
            }
            .toolbarBackground(theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView(settings: settings, coordinator: coordinator)
            }
            .task { await coordinator.sync(startDate: settings.startDate) }
        }
    }

    private func refresh() {
        Task { await coordinator.sync(startDate: settings.startDate) }
    }
}

private struct EmptyStateView: View {
    @Environment(\.theme) private var theme
    let syncState: SyncCoordinator.State
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("$ ls runs/")
                .terminalFont(16, weight: .bold)
                .foregroundColor(theme.cyan)
            switch syncState {
            case .syncing:
                Text("// syncing…")
                    .terminalFont(12)
                    .foregroundColor(theme.comment)
            case .error(let msg):
                Text("[error] \(msg)")
                    .terminalFont(12)
                    .foregroundColor(theme.red)
                    .multilineTextAlignment(.center)
            case .idle:
                Text("// no runs found since your start date")
                    .terminalFont(12)
                    .foregroundColor(theme.comment)
                Text("// if this looks wrong, check Health permissions")
                    .terminalFont(12)
                    .foregroundColor(theme.comment)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Link("[ open settings ]", destination: url)
                        .terminalFont(12, weight: .bold)
                        .foregroundColor(theme.yellow)
                }
                Button("[ retry ]", action: onRetry)
                    .buttonStyle(TerminalButtonStyle(color: theme.cyan))
            }
        }
        .padding(24)
    }
}
