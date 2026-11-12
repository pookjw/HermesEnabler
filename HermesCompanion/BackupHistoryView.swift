import SwiftUI

// MARK: - Backup History

struct BackupHistoryView: View {

    @ObservedObject var manager: WatchConnectivityManager

    @Environment(\.dismiss) private var dismiss

    @State private var shareURL: ShareItem?
    @State private var selectedBackup: WatchConnectivityManager.BackupRecord?
    @State private var verificationMessage: String?
    @State private var showingVerification = false

    var body: some View {

        NavigationStack {

            List {

                if manager.backups.isEmpty {

                    ContentUnavailableView(
                        "No Backups",
                        systemImage: "externaldrive",
                        description: Text(
                            "Backups will appear here."
                        )
                    )
                }

                ForEach(manager.backups) { record in

                    NavigationLink {
                        BackupDetailView(
                            manager: manager,
                            record: record
                        )
                    } label: {

                        BackupHistoryRow(record: record)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        manager.loadBackupHistory()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
