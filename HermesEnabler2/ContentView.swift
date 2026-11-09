import SwiftUI

struct ContentView: View {
    @State private var message = BQBackupExists() ? "Backup ready." : "Back up MobileGestalt before making changes."
    @State private var hasBackup = BQBackupExists()

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Hermès Enabler").font(.headline)
                if !hasBackup {
                    Button("Backup MG") { perform(.backup) }
                }
                Button("Enable Hermès") { perform(.enable) }
                    .disabled(!hasBackup)
                Button("Restart Carousel") {
                    message = "Starting respring. View the app log if nothing happens."
                    BQRespring()
                }
                Button("Restore MG") { perform(.restore) }
                    .disabled(!hasBackup)
                Text(message).font(.footnote).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private enum Action { case backup, enable, restore }

    private func perform(_ action: Action) {
        var error: NSString?
        let result: String
        if !BQCoreInit() {
            result = "MobileGestalt access is unavailable on this device."
        } else {
            switch action {
            case .backup:
                if BQBackupExists() {
                    result = "A backup already exists and was preserved."
                } else if BQLoadGestalt(&error) != nil && BQBackupExists() {
                    result = "MobileGestalt backup saved."
                } else {
                    result = (error as String?) ?? "Backup could not be verified."
                }
            case .enable:
                if BQEnableHermes(&error) {
                    result = "DeviceBrand saved."
                } else {
                    result = (error as String?) ?? "Could not update DeviceBrand."
                }
            case .restore:
                result = BQRestoreGestalt(&error) ? "MobileGestalt restored. Restart the watch to reload it." : ((error as String?) ?? "Restore failed.")
            }
        }
        hasBackup = BQBackupExists()
        message = result
    }
}
