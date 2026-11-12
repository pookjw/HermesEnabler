//
//  WatchConnectivityManager.swift
//  HermesEnabler2
//
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

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
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingHistory = false
    @State private var showingImporter = false
    @State private var shareURL: ShareItem?
    @State private var alertMessage = ""
    @State private var showingAlert = false

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 22) {

                    watchCard
                    
                    installationCard

                    backupCard

                    actionButtons
                }
                .padding()
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("HermesEnabler")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        watchManager.loadBackupHistory()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Actualiser")
                }
            }
        }
        .sheet(isPresented: $showingHistory) {
            BackupHistoryView(manager: watchManager)
        }
        .sheet(item: $shareURL) { item in
            ActivityViewController(activityItems: [item.url])
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.propertyList],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert("HermesEnabler", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                watchManager.refreshConnectionStatus()
                watchManager.loadBackupHistory()
            }
        }
    }

    // MARK: - Watch card

    private var watchCard: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 14) {

                Image(systemName: "applewatch")
                    .font(.system(size: 34, weight: .light))
                    .frame(width: 58, height: 58)
                    .background(
                        Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 16)
                    )

                VStack(alignment: .leading, spacing: 5) {

                    Text(watchManager.deviceName)
                        .font(.headline)

                    Text(watchManager.model)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if watchManager.watchOSVersion != "Unknown" {
                Text(
                    "watchOS \(watchManager.watchOSVersion) · \(watchManager.buildVersion)"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }
    
    // MARK: - Watch installation status

    private var installationCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 10) {
                Image(systemName: installationIcon)
                    .font(.title2)
                    .foregroundStyle(installationColor)

                Text(installationTitle)
                    .font(.headline)

                Spacer()

                Circle()
                    .fill(installationColor)
                    .frame(width: 9, height: 9)
            }

            Text(installationMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if watchManager.isPaired && !watchManager.isWatchAppInstalled {
                Divider()

                Label(
                    "Comment installer HermesEnabler",
                    systemImage: "applewatch"
                )
                .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Label("Ouvrez l'application Watch sur votre iPhone.", systemImage: "1.circle")
                    Label("Recherchez HermesEnabler dans la liste des apps.", systemImage: "2.circle")
                    Label("Appuyez sur Installer.", systemImage: "3.circle")
                    Label("Une fois installée, ouvrez l'application sur votre Apple Watch.", systemImage: "4.circle")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

            } else if watchManager.isPaired && watchManager.isWatchAppInstalled && !watchManager.isReachable {
                Divider()

                Label(
                    "Ouvrez HermesEnabler directement sur votre Apple Watch.",
                    systemImage: "hand.tap"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    private var installationTitle: String {
        if !watchManager.isPaired {
            return "Apple Watch non jumelée"
        }

        if !watchManager.isWatchAppInstalled {
            return "Installation nécessaire"
        }

        if watchManager.isReachable {
            return "HermesEnabler est opérationnelle"
        }

        return "Application installée"
    }

    private var installationMessage: String {
        if !watchManager.isPaired {
            return "Jumelez votre Apple Watch avec cet iPhone pour pouvoir utiliser HermesEnabler."
        }

        if !watchManager.isWatchAppInstalled {
            return "HermesEnabler est installée sur l'iPhone, mais son application compagnon n'est pas encore installée sur l'Apple Watch."
        }

        if watchManager.isReachable {
            return "Votre Apple Watch communique actuellement avec HermesCompanion."
        }

        return "L'application est installée, mais votre Apple Watch ne communique pas actuellement avec HermesCompanion. Ouvrez HermesEnabler sur la montre."
    }

    private var installationIcon: String {
        if !watchManager.isPaired {
            return "applewatch.slash"
        }

        if !watchManager.isWatchAppInstalled {
            return "arrow.down.app"
        }

        if watchManager.isReachable {
            return "checkmark.circle.fill"
        }

        return "applewatch"
    }

    private var installationColor: Color {
        if !watchManager.isPaired {
            return .secondary
        }

        if !watchManager.isWatchAppInstalled {
            return .orange
        }

        if watchManager.isReachable {
            return .green
        }

        return .orange
    }

    private var watchStatusText: String {
        if !watchManager.isPaired {
            return "Aucune montre associée"
        }

        if !watchManager.isWatchAppInstalled {
            return "Application à installer"
        }

        if watchManager.isReachable {
            return "Connectée"
        }

        return "Installée, non joignable"
    }

    private var watchStatusColor: Color {
        if watchManager.isReachable {
            return .green
        }

        if watchManager.isPaired {
            return .orange
        }

        return .secondary
    }

    // MARK: - Backup card

    private var backupCard: some View {

        VStack(alignment: .leading, spacing: 14) {

            HStack {

                Text("MobileGestalt")
                    .font(.headline)

                Spacer()

                Text("\(watchManager.backups.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Divider()

            if let latest = watchManager.latestBackup {

                VStack(alignment: .leading, spacing: 7) {

                    Label(
                        "Dernière sauvegarde",
                        systemImage: "externaldrive.fill"
                    )
                    .font(.subheadline.weight(.medium))

                    Text(latest.date.formatted(
                        date: .abbreviated,
                        time: .shortened
                    ))
                    .font(.title3.weight(.semibold))

                    HStack {

                        Text(latest.formattedSize)

                        Spacer()

                        Text(latest.hashOrigin)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

            } else {

                ContentUnavailableView(
                    "Aucune sauvegarde",
                    systemImage: "externaldrive",
                    description: Text(
                        "Importez un fichier ou recevez une sauvegarde depuis votre Apple Watch."
                    )
                )
                .frame(minHeight: 150)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    // MARK: - Main actions

    private var actionButtons: some View {

        VStack(spacing: 12) {

            Button {
                showingImporter = true
            } label: {
                Label(
                    "Importer une sauvegarde",
                    systemImage: "square.and.arrow.down"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)

            Button {
                guard let latest = watchManager.latestBackup else {
                    showMessage("Aucune sauvegarde à exporter.")
                    return
                }

                exportBackup(latest)

            } label: {
                Label(
                    "Exporter la dernière sauvegarde",
                    systemImage: "square.and.arrow.up"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
            }
            .buttonStyle(.bordered)

            Button {
                watchManager.loadBackupHistory()
                showingHistory = true
            } label: {
                Label(
                    "Historique des sauvegardes",
                    systemImage: "clock.arrow.circlepath"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Import

    private func handleImport(
        _ result: Result<[URL], Error>
    ) {

        switch result {

        case .success(let urls):

            guard let url = urls.first else {
                return
            }

            do {
                switch try watchManager.importBackup(from: url) {

                case .imported(let record):

                    showMessage(
                        """
                        Sauvegarde importée avec succès.

                        Taille : \(record.formattedSize)

                        SHA-256 vérifié.
                        """
                    )

                case .duplicate:

                    showMessage(
                        """
                        Import refusé.

                        Une sauvegarde identique est déjà présente dans l'historique.

                        Aucun fichier supplémentaire n'a été créé.
                        """
                    )
                }

            } catch {

                showMessage(
                    "Impossible d'importer la sauvegarde :\n\(error.localizedDescription)"
                )
            }

        case .failure(let error):

            showMessage(
                "Erreur lors de la sélection du fichier :\n\(error.localizedDescription)"
            )
        }
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
    @State private var selectedBackup: WatchConnectivityManager.BackupRecord?
    @State private var verificationMessage: String?
    @State private var showingVerification = false

    var body: some View {

        NavigationStack {

            List {

                if manager.backups.isEmpty {

                    ContentUnavailableView(
                        "Aucune sauvegarde",
                        systemImage: "externaldrive",
                        description: Text(
                            "Les sauvegardes apparaîtront ici."
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
            .navigationTitle("Historique")
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
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Backup History Row

struct BackupHistoryRow: View {

    let record: WatchConnectivityManager.BackupRecord

    var body: some View {

        HStack(spacing: 13) {

            Image(systemName: "doc.zipper")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 42, height: 42)
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 12)
                )

            VStack(alignment: .leading, spacing: 5) {

                Text(record.date.formatted(
                    date: .abbreviated,
                    time: .shortened
                ))
                .font(.subheadline.weight(.semibold))

                Text(record.hashOrigin)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(record.formattedSize)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Backup Detail

struct BackupDetailView: View {

    @ObservedObject var manager: WatchConnectivityManager

    let record: WatchConnectivityManager.BackupRecord

    @State private var shareURL: ShareItem?
    @State private var verificationMessage: String?
    @State private var showingVerification = false

    var body: some View {

        List {

            Section("Sauvegarde") {

                detailRow("Date", value: record.formattedDate)
                detailRow("Taille", value: record.formattedSize)
                detailRow("Origine", value: record.hashOrigin)
                detailRow("Appareil", value: record.deviceIdentifier)
            }

            Section("Intégrité") {

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
                        "Vérifier l'intégrité",
                        systemImage: "checkmark.shield"
                    )
                }
            }

            Section("Fichier") {

                Text(record.fileName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                Button {
                    exportBackup()
                } label: {
                    Label(
                        "Exporter cette sauvegarde",
                        systemImage: "square.and.arrow.up"
                    )
                }
            }

            if let message = verificationMessage {

                Section("Résultat") {
                    Text(message)
                        .font(.footnote)
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Détails")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    sendBackupToWatch()
                } label: {
                    Image(systemName: "applewatch")
                        .font(.system(size: 17, weight: .medium))
                }
                .accessibilityLabel("Envoyer à l'Apple Watch")
                .disabled(!manager.isPaired || !manager.isWatchAppInstalled)
            }
        }
        .sheet(item: $shareURL) { item in
            ActivityViewController(activityItems: [item.url])
        }
        .alert(
            "Vérification",
            isPresented: $showingVerification
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(verificationMessage ?? "")
        }
    }

    private func detailRow(
        _ title: String,
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
                "Intégrité confirmée. Le SHA-256 correspond."

        case .invalid:
            verificationMessage =
                "Attention : le fichier ne correspond plus à son empreinte."

        case .missing:
            verificationMessage =
                "Le fichier est introuvable."

        case .error(let message):
            verificationMessage =
                "Erreur de vérification : \(message)"
        }

        showingVerification = true
    }

    // MARK: - Export

    private func exportBackup() {

        guard let url = manager.exportURL(for: record) else {
            verificationMessage =
                "Impossible de trouver le fichier à exporter."
            showingVerification = true
            return
        }

        shareURL = ShareItem(url: url)
    }
    
    // MARK: - Transfer to Apple Watch

    private func sendBackupToWatch() {

        guard let url = manager.exportURL(for: record) else {
            verificationMessage = "Impossible de trouver le fichier à envoyer."
            showingVerification = true
            return
        }

        guard manager.isPaired && manager.isWatchAppInstalled else {
            verificationMessage = "Aucune Apple Watch compatible n'est disponible."
            showingVerification = true
            return
        }

        let queued = manager.transferBackupToWatch(at: url)

        if queued {
            verificationMessage = """
            Transfert de la sauvegarde mis en attente.

            Fichier : \(record.fileName)

            La sauvegarde sera enregistrée sur l'Apple Watch sans modifier la sauvegarde originale.

            Le transfert est en attente de confirmation de réception par la montre.
            """
        } else {
            verificationMessage = "Impossible de mettre le transfert en attente. Vérifiez la connexion avec votre Apple Watch."
        }

        showingVerification = true
    }
    
}
