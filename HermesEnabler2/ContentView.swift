import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model = ContentModel()

    var body: some View {
        NavigationStack {
            if !model.hasBackup {
                BackupView(model: model)
            } else {
                List {
                    Section("Features") {
                        NavigationLink { WatchFacesView(model: model) } label: {
                            Label("Watch Faces", systemImage: "clock")
                        }
                        NavigationLink { DisplayAndControlsView(model: model) } label: {
                            Label("Display & Controls", systemImage: "switch.2")
                        }
                        NavigationLink { SensorsAndWorkoutsView(model: model) } label: {
                            Label("Sensors & Workouts", systemImage: "heart")
                        }
                        NavigationLink { IntelligenceView(model: model) } label: {
                            Label("Siri & Intelligence", systemImage: "sparkles")
                        }
                    }
                    Section("Utilities") {
                        NavigationLink { BackupView(model: model) } label: {
                            Label("MG Backups", systemImage: "archivebox")
                        }
                    }
                    Section("Status") {
                        Text(LocalizedStringKey(model.message))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("HermesEnabler")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            model.message = "Starting respring. View the app log if nothing happens."
                            BQRespring()
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .accessibilityLabel("Restart Carousel")
                    }
                }
            }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active {
                model.refreshBackups()
                model.refreshCapabilityStates()
            }
        }
        .confirmationDialog("Restore this backup?", isPresented: $model.showRestoreConfirmation) {
            Button("Restore MG", role: .destructive) { model.perform(.restoreBackup(model.selectedBackupID)) }
        } message: {
            Text("The current MG will be backed up automatically first. Restart the watch after restoring.")
        }
        .alert("MobileGestalt Access Failed", isPresented: $model.showAccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("An App Group ID may be missing, or this watchOS version may be incompatible. Check the app's App Group configuration and watchOS version.")
        }
        .alert("Could Not Change Setting", isPresented: Binding(
            get: { model.toggleError != nil },
            set: { if !$0 { model.toggleError = nil } }
        ), presenting: model.toggleError) { _ in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error.message)
        }
    }
}
