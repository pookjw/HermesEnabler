//
//  WatchConnectivityManager.swift
//  HermesEnabler2
//
//

import SwiftUI
import UIKit

@main
struct HermesCompanionApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Content View

struct ContentView: View {

    @StateObject private var watchManager = WatchConnectivityManager()

    @State private var showingHistory = false
    @State private var shareURL: ShareItem?
    @State private var alertMessage = ""
    @State private var showingAlert = false

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                // Header
                header

                // App Title
                Text("HermesEnabler")
                    .font(.system(size: 27, weight: .bold))

                // Connected device
                deviceSection

                Divider()

                // Backup status
                backupSection

                Divider()

                // Actions
                actionsSection

                // Footer
                Text("HermesEnabler Companion")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(24)
            .frame(maxWidth: 760)
            .background(Color(uiColor: .systemBackground))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        Color(uiColor: .separator).opacity(0.35),
                        lineWidth: 1
                    )
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: .systemBackground))

        // Backup history
        .sheet(isPresented: $showingHistory) {
            BackupHistoryView(manager: watchManager)
        }

        // Export from main screen
        .sheet(item: $shareURL) { item in
            ActivityViewController(activityItems: [item.url])
        }

        // Main screen alerts only
        .alert("HermesEnabler", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Header

    private var header: some View {

        HStack {

            Button {
                watchManager.loadBackupHistory()
            } label: {
                Image(systemName: "arrow.clockwise")
            }

            Spacer()

            if watchManager.isReachable {

                Label("Connecté", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.green.opacity(0.12), in: Capsule())

            } else if watchManager.isPaired &&
                        watchManager.isWatchAppInstalled {

                Label("Montre associée", systemImage: "applewatch")
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.orange.opacity(0.12), in: Capsule())

            } else {

                Label("Non connecté", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.secondary.opacity(0.12), in: Capsule())
            }
        }
    }

    // MARK: - Device

    private var deviceSection: some View {

        HStack(spacing: 20) {

            ZStack {

                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .frame(width: 108, height: 108)

                Image(systemName: "applewatch")
                    .font(.system(size: 53, weight: .light))
                    .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: 7) {

                Text(watchManager.deviceName)
                    .font(.system(size: 20, weight: .semibold))

                Text(
                    "watchOS \(watchManager.watchOSVersion) · " +
                    watchManager.buildVersion
                )
                .font(.system(size: 16))
                .foregroundStyle(.secondary)

                Text(
                    watchManager.isPaired
                    ? "Apple Watch associée"
                    : "Aucune montre associée"
                )
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(
                    watchManager.isPaired ? .green : .secondary
                )
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Backup Section

    private var backupSection: some View {

        VStack(alignment: .leading, spacing: 20) {

            Text("MobileGestalt Backup")
                .font(.system(size: 21, weight: .bold))

            BackupStatusRow(
                title: "iPhone Backup",
                subtitle: "Copies indépendantes enregistrées",
                status: "\(watchManager.backups.count)",
                color: watchManager.backups.isEmpty ? .secondary : .green
            )

            if let latest = watchManager.latestBackup {

                VStack(alignment: .leading, spacing: 8) {

                    Text("Dernière sauvegarde")
                        .font(.system(size: 16, weight: .semibold))

                    Text(latest.fileName)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)

                    Text(
                        latest.date.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                    Text(latest.formattedSize)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    Text("SHA-256")
                        .font(.system(size: 13, weight: .semibold))

                    Text(latest.sha256)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)

                    Text(latest.hashOrigin)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Button {
                    verifyBackup(latest)
                } label: {
                    Label(
                        "Vérifier l'intégrité",
                        systemImage: "checkmark.shield"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

            } else {

                Text("Aucune sauvegarde enregistrée sur l'iPhone.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {

        VStack(alignment: .leading, spacing: 22) {

            BackupActionRow(
                icon: "square.and.arrow.up",
                title: "Exporter la dernière sauvegarde",
                color: .green
            ) {

                guard let latest = watchManager.latestBackup else {
                    showMessage("Aucune sauvegarde à exporter.")
                    return
                }

                exportBackup(latest)
            }

            BackupActionRow(
                icon: "clock.arrow.circlepath",
                title: "Historique des sauvegardes"
            ) {

                watchManager.loadBackupHistory()
                showingHistory = true
            }

            BackupActionRow(
                icon: "checkmark.shield",
                title: "Vérifier toutes les sauvegardes"
            ) {

                verifyAllBackups()
            }
        }
    }

    // MARK: - Verification

    private func verifyBackup(
        _ record: WatchConnectivityManager.BackupRecord
    ) {

        switch watchManager.verifyBackup(record) {

        case .valid:

            showMessage(
                "Intégrité confirmée.\n\n" +
                "Le SHA-256 correspond à l'empreinte enregistrée."
            )

        case .invalid:

            showMessage(
                "ATTENTION : le SHA-256 ne correspond plus.\n\n" +
                "Le fichier a peut-être été modifié ou endommagé."
            )

        case .missing:

            showMessage(
                "Le fichier de sauvegarde est introuvable."
            )

        case .error(let message):

            showMessage(
                "Erreur de vérification : \(message)"
            )
        }
    }

    private func verifyAllBackups() {

        guard !watchManager.backups.isEmpty else {
            showMessage("Aucune sauvegarde à vérifier.")
            return
        }

        var valid = 0
        var invalid = 0
        var missing = 0
        var errors = 0

        for record in watchManager.backups {

            switch watchManager.verifyBackup(record) {

            case .valid:
                valid += 1

            case .invalid:
                invalid += 1

            case .missing:
                missing += 1

            case .error:
                errors += 1
            }
        }

        showMessage("""
        Vérification terminée.

        Intègres : \(valid)
        Modifiées : \(invalid)
        Introuvables : \(missing)
        Erreurs : \(errors)
        """)
    }

    // MARK: - Export

    private func exportBackup(
        _ record: WatchConnectivityManager.BackupRecord
    ) {

        guard let url = watchManager.exportURL(for: record) else {
            showMessage("Impossible de trouver le fichier à exporter.")
            return
        }

        shareURL = ShareItem(url: url)
    }

    // MARK: - Alert

    private func showMessage(_ message: String) {

        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Share Item

struct ShareItem: Identifiable {

    let id = UUID()
    let url: URL
}

// MARK: - Native iOS Share Sheet

struct ActivityViewController: UIViewControllerRepresentable {

    let activityItems: [Any]

    init(activityItems: [Any]) {
        self.activityItems = activityItems
    }

    func makeUIViewController(
        context: Context
    ) -> UIActivityViewController {

        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ controller: UIActivityViewController,
        context: Context
    ) { }
}

// MARK: - Backup History

struct BackupHistoryView: View {

    @ObservedObject var manager: WatchConnectivityManager

    @Environment(\.dismiss) private var dismiss

    @State private var shareURL: ShareItem?
    @State private var verificationMessage: String?

    var body: some View {

        NavigationStack {

            List {

                // Verification result
                if let message = verificationMessage {

                    Section {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }

                // Empty history
                if manager.backups.isEmpty {

                    ContentUnavailableView(
                        "Aucune sauvegarde",
                        systemImage: "externaldrive",
                        description: Text(
                            "Les sauvegardes reçues apparaîtront ici."
                        )
                    )
                }

                // Backup records
                ForEach(manager.backups) { record in

                    VStack(alignment: .leading, spacing: 10) {

                        Text(record.fileName)
                            .font(.system(size: 14, weight: .semibold))
                            .textSelection(.enabled)

                        Text(
                            record.date.formatted(
                                date: .abbreviated,
                                time: .shortened
                            )
                        )
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                        HStack {

                            Text(record.formattedSize)

                            Spacer()

                            Text(record.deviceIdentifier)
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                        Text("SHA-256")
                            .font(.system(size: 12, weight: .semibold))

                        Text(record.sha256)
                            .font(.system(size: 10, design: .monospaced))
                            .textSelection(.enabled)
                            .foregroundStyle(.secondary)

                        Text(record.hashOrigin)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)

                        HStack {

                            // Verify
                            Button {
                                verify(record)
                            } label: {
                                Label(
                                    "Vérifier",
                                    systemImage: "checkmark.shield"
                                )
                            }

                            Spacer()

                            // Export
                            Button {

                                guard let url = manager.exportURL(
                                    for: record
                                ) else {

                                    verificationMessage =
                                        "Impossible de trouver le fichier."

                                    return
                                }

                                shareURL = ShareItem(url: url)

                            } label: {

                                Label(
                                    "Exporter",
                                    systemImage: "square.and.arrow.up"
                                )
                            }
                        }
                        .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Historique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }

        // Share sheet attached to history
        .sheet(item: $shareURL) { item in

            ActivityViewController(
                activityItems: [item.url]
            )
        }
    }

    // MARK: - Verification

    private func verify(
        _ record: WatchConnectivityManager.BackupRecord
    ) {

        switch manager.verifyBackup(record) {

        case .valid:

            verificationMessage =
                "Intégrité confirmée : le SHA-256 correspond."

        case .invalid:

            verificationMessage =
                "ATTENTION : le fichier ne correspond plus à son empreinte."

        case .missing:

            verificationMessage =
                "Le fichier est introuvable."

        case .error(let message):

            verificationMessage =
                "Erreur de vérification : \(message)"
        }
    }
}

// MARK: - Backup Status Row

struct BackupStatusRow: View {

    let title: String
    let subtitle: String
    let status: String
    let color: Color

    var body: some View {

        HStack {

            VStack(alignment: .leading, spacing: 7) {

                Text(title)
                    .font(.system(size: 19, weight: .semibold))

                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(status)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(color.opacity(0.12), in: Capsule())
        }
    }
}

// MARK: - Backup Action Row

struct BackupActionRow: View {

    let icon: String
    let title: String
    var color: Color = .primary
    let action: () -> Void

    var body: some View {

        Button(action: action) {

            HStack(spacing: 13) {

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
