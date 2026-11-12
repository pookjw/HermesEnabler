import SwiftUI

// MARK: - Backup Detail

struct BackupDetailView: View {

    @ObservedObject var manager: WatchConnectivityManager

    let record: WatchConnectivityManager.BackupRecord

    @State private var shareURL: ShareItem?
    @State private var verificationMessage: String?
    @State private var showingVerification = false

    var body: some View {

        List {

            Section("Backup") {

                detailRow("Date", value: record.formattedDate)
                detailRow("Size", value: record.formattedSize)
                detailRow("Source", value: NSLocalizedString(record.hashOrigin, comment: "Backup source"))
                detailRow("Device", value: NSLocalizedString(record.deviceIdentifier, comment: "Backup source device"))
            }

            Section("Integrity") {

                VStack(alignment: .leading, spacing: 8) {

                    Text("SHA-256")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(record.sha256)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
                .padding(.vertical, 5)

                Button {
                    verifyBackup()
                } label: {
                    Label(
                        "Verify Integrity",
                        systemImage: "checkmark.shield"
                    )
                }
            }

            Section("File") {

                Text(record.fileName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                Button {
                    exportBackup()
                } label: {
                    Label(
                        "Export This Backup",
                        systemImage: "square.and.arrow.up"
                    )
                }
            }

            if let message = verificationMessage {

                Section("Result") {
                    Text(message)
                        .font(.footnote)
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    sendBackupToWatch()
                } label: {
                    Image(systemName: "applewatch")
                        .font(.system(size: 17, weight: .medium))
                }
                .accessibilityLabel("Send to Apple Watch")
                .disabled(!manager.isPaired || !manager.isWatchAppInstalled)
            }
        }
        .sheet(item: $shareURL) { item in
            ActivityViewController(activityItems: [item.url])
        }
        .alert(
            "Verification",
            isPresented: $showingVerification
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(verificationMessage ?? "")
        }
    }

    private func detailRow(
        _ title: LocalizedStringKey,
        value: String
    ) -> some View {

        HStack {

            Text(title)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Verification

    private func verifyBackup() {

        switch manager.verifyBackup(record) {

        case .valid:
            verificationMessage =
                String(localized: "Integrity confirmed. The SHA-256 matches.")

        case .invalid:
            verificationMessage =
                String(localized: "The file no longer matches its checksum.")

        case .missing:
            verificationMessage =
                String(localized: "The file could not be found.")

        case .error(let message):
            verificationMessage =
                String(localized: "Verification error: \(message)")
        }

        showingVerification = true
    }

    // MARK: - Export

    private func exportBackup() {

        guard let url = manager.exportURL(for: record) else {
            verificationMessage =
                String(localized: "The file to export could not be found.")
            showingVerification = true
            return
        }

        shareURL = ShareItem(url: url)
    }

    // MARK: - Transfer to Apple Watch

    private func sendBackupToWatch() {

        guard let url = manager.exportURL(for: record) else {
            verificationMessage = String(localized: "The file to send could not be found.")
            showingVerification = true
            return
        }

        guard manager.isPaired && manager.isWatchAppInstalled else {
            verificationMessage = String(localized: "No compatible Apple Watch is available.")
            showingVerification = true
            return
        }

        let queued = manager.transferBackupToWatch(at: url)

        if queued {
            verificationMessage = String(localized: "Backup transfer queued: \(record.fileName). Confirm the import on your Apple Watch.")
        } else {
            verificationMessage = String(localized: "Could not queue the transfer. Check your Apple Watch connection.")
        }

        showingVerification = true
    }

}
