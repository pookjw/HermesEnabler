import SwiftUI

struct BackupView: View {
    let model: ContentModel

    var body: some View {
        List {
            if !model.hasBackup {
                Section("First Launch") {
                    Text("An initial MobileGestalt backup is required before using any feature. It will be kept as the original and cannot be overwritten here.")
                        .font(.footnote)
                    Button("Create Initial Backup") { model.perform(.backup) }
                }
            } else {
                Section("Create Backup") {
                    Button("Back Up Current MG") { model.perform(.manualBackup) }
                    Text("Every MG write and restore also creates an automatic backup first.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
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
                    if model.backups.contains(where: { $0.id != "initial" }) {
                        Text("Swipe a backup left to delete it. The initial backup is protected.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
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
            Section("Status") { Text(LocalizedStringKey(model.message)).font(.footnote).foregroundStyle(.secondary) }
        }
        .navigationTitle("MG Backups")
        .onAppear(perform: model.refreshBackups)
    }
}
