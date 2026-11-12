
import SwiftUI

struct BackupView: View {

    let model: ContentModel

    var body: some View {

        List {

            // Initial backup requirement
            if !model.hasBackup {

                Section("First Launch") {

                    Text("An initial MobileGestalt backup is required before using any feature. It will be kept as the original and cannot be overwritten here.")

                        .font(.footnote)

                    Button("Create Initial Backup") {
                        model.perform(.backup)
                    }
                }

            } else {

                Section("Create Backup") {

                    Button("Back Up Current MG") {
                        model.perform(.manualBackup)
                    }

                    Text("Every MG write and restore also creates an automatic backup first.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            // Backup library is always visible,
            // including when only external backups exist.
            Section("Backup Library") {

                if model.backups.isEmpty {

                    Text("No backups available.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                } else {

                    ForEach(model.backups) { backup in

                        Button {

                            model.selectedBackupID = backup.id
                            model.showRestoreConfirmation = true

                        } label: {

                            VStack(alignment: .leading, spacing: 4) {

                                HStack {

                                    Text(LocalizedStringKey(backup.kind + " Backup"))
                                        .font(.body)

                                    Spacer()

                                    if backup.kind == "External" {
                                        Text("IMPORTED")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.blue)
                                    }
                                }

                                Text(backup.date.formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                ))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {

                            if backup.id != "initial" {

                                Button(role: .destructive) {

                                    model.perform(.deleteBackup(backup.id))

                                } label: {

                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }

                    Text("Swipe a backup left to delete it. The initial backup is protected.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if !model.hasBackup && !model.backups.isEmpty {
                Section("Backup Library") {
                    ForEach(model.backups) { backup in
                        Button {
                            model.selectedBackupID = backup.id
                            model.showRestoreConfirmation = true
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedStringKey(backup.kind + " Backup"))
                                Text(backup.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            Section("Status") { Text(LocalizedStringKey(model.message))
                .font(.footnote)
                .foregroundStyle(.secondary) }
        }
        .navigationTitle("MG Backups")
        .onAppear {
            model.refreshBackups()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("HermesExternalBackupReceived")
            )
        ) { notification in

            guard
                let data = notification.userInfo?["data"] as? Data,
                let fileName = notification.userInfo?["fileName"] as? String,
                let sha256 = notification.userInfo?["sha256"] as? String
            else {
                print("[UI] Invalid external backup notification")
                return
            }

            print("[UI] External backup waiting for user confirmation")

            model.prepareExternalBackupImport(
                data: data,
                fileName: fileName,
                sha256: sha256
            )
        }
        .alert(
            "New External Backup",
            isPresented: Binding(
                get: { model.showExternalImportConfirmation },
                set: { model.showExternalImportConfirmation = $0 }
            )
        ) {

            Button("Accept and Import") {
                model.confirmExternalBackupImport()
            }

            Button("Reject", role: .destructive) {
                model.rejectExternalBackupImport()
            }

            Button("Cancel", role: .cancel) {
                model.rejectExternalBackupImport()
            }

        } message: {

            Text(
                """
                A backup has been received from your iPhone.

                File: \(model.pendingExternalBackupName)

                SHA-256:
                \(model.pendingExternalBackupSHA256)

                The file will only be added to the backup library.
                No MobileGestalt restoration will be performed.
                """
            )
        }
    }
}
