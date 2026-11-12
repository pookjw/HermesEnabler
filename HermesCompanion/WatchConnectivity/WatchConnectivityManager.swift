//
//  WatchConnectivityManager.swift
//  HermesEnabler2
//
//

import Foundation
import WatchConnectivity
import Combine
import CryptoKit

@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {

    // MARK: - Connection

    @Published var isPaired = false
    @Published var isWatchAppInstalled = false
    @Published var isReachable = false

    // MARK: - Watch information

    @Published var deviceName = "Apple Watch"
    @Published var model = "Unknown"
    @Published var localizedModel = "Unknown"
    @Published var hardwareIdentifier = "Unknown"
    @Published var watchOSVersion = "Unknown"
    @Published var buildVersion = "Unknown"
    @Published var lastUpdate: Date?

    // MARK: - Backup information

    @Published var backups: [BackupRecord] = []
    @Published var backupStatus = "Aucune sauvegarde"
    @Published var lastVerificationMessage = ""

    private var session: WCSession?

    // MARK: - Backup model

    struct BackupRecord: Identifiable, Codable {
        let id: UUID
        let fileName: String
        let date: Date
        let size: Int
        let sha256: String
        let deviceIdentifier: String
        let hashOrigin: String

        var formattedSize: String {
            ByteCountFormatter.string(
                fromByteCount: Int64(size),
                countStyle: .file
            )
        }

        var formattedDate: String {
            date.formatted(
                date: .long,
                time: .shortened
            )
        }
    }

    private struct BackupManifest: Codable {
        var backups: [BackupRecord]
    }

    enum VerificationResult {
        case valid
        case invalid
        case missing
        case error(String)
    }

    enum ImportResult {
        case imported(BackupRecord)
        case duplicate
    }

    // MARK: - Paths

    private static func backupDirectory() throws -> URL {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let directory = support
            .appendingPathComponent(
                "HermesEnabler",
                isDirectory: true
            )
            .appendingPathComponent(
                "Backups",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return directory
    }

    private static func manifestURL() throws -> URL {
        try backupDirectory()
            .appendingPathComponent("BackupManifest.json")
    }

    private static func backupURL(for fileName: String) throws -> URL {
        try backupDirectory()
            .appendingPathComponent(fileName)
    }

    // MARK: - SHA-256

    private nonisolated static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }

    // MARK: - Manifest

    private static func saveManifest(
        _ records: [BackupRecord]
    ) throws {
        let manifest = BackupManifest(backups: records)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(manifest)
        let url = try manifestURL()

        try data.write(to: url, options: .atomic)
    }

    private static func loadManifest() throws -> [BackupRecord] {
        let url = try manifestURL()

        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(
            BackupManifest.self,
            from: data
        ).backups
    }

    // MARK: - Initialization

    override init() {
        super.init()

        loadBackupHistory()

        guard WCSession.isSupported() else {
            print("[WC] WatchConnectivity not supported")
            return
        }

        let session = WCSession.default
        self.session = session
        session.delegate = self
        session.activate()

        print("[WC] iPhone session activation requested")
    }

    // MARK: - History

    func loadBackupHistory() {
        do {
            var records = try Self.loadManifest()
            let directory = try Self.backupDirectory()

            let files = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [
                    .fileSizeKey,
                    .creationDateKey
                ],
                options: [.skipsHiddenFiles]
            )

            let knownFiles = Set(records.map(\.fileName))

            for file in files {
                guard file.pathExtension == "plist",
                      file.lastPathComponent.hasPrefix("OriginalGestalt-"),
                      !knownFiles.contains(file.lastPathComponent) else {
                    continue
                }

                do {
                    let data = try Data(contentsOf: file)
                    try Self.validateBackup(data)

                    let attributes = try FileManager.default.attributesOfItem(
                        atPath: file.path
                    )

                    let date = attributes[.creationDate] as? Date ?? Date()

                    let record = BackupRecord(
                        id: UUID(),
                        fileName: file.lastPathComponent,
                        date: date,
                        size: data.count,
                        sha256: Self.sha256(data),
                        deviceIdentifier: "Unknown",
                        hashOrigin: "Initial iPhone baseline"
                    )

                    records.append(record)

                    print("[WC] Baseline created: \(record.fileName)")

                } catch {
                    print("[WC] Migration failed: \(error)")
                }
            }

            records.sort { $0.date > $1.date }

            try Self.saveManifest(records)

            backups = records

            backupStatus = records.isEmpty
                ? "Aucune sauvegarde"
                : "\(records.count) sauvegarde(s)"

            print("[WC] Backup history loaded: \(records.count)")

        } catch {
            print("[WC] History loading error: \(error.localizedDescription)")
            backupStatus = "Erreur de chargement"
        }
    }

    // MARK: - Backup validation

    private nonisolated static func validateBackup(
        _ data: Data
    ) throws {
        let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        )

        guard let dictionary = plist as? [String: Any],
              dictionary["CacheExtra"] is [String: Any],
              dictionary["CacheData"] is Data else {
            throw NSError(
                domain: "HermesCompanion.Backup",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Structure MobileGestalt invalide."
                ]
            )
        }
    }

    // MARK: - Connection status

    private func updateStatus(_ session: WCSession) {
        isPaired = session.isPaired
        isWatchAppInstalled = session.isWatchAppInstalled
        isReachable = session.isReachable

        print("""
        [WC] Connection status:
        Paired: \(isPaired)
        Watch app installed: \(isWatchAppInstalled)
        Reachable: \(isReachable)
        """)
    }

    // MARK: - Device information

    private func updateDeviceInformation(_ info: [String: Any]) {
        if let value = info["deviceName"] as? String {
            deviceName = value
        }

        if let value = info["model"] as? String {
            model = value
        }

        if let value = info["localizedModel"] as? String {
            localizedModel = value
        }

        if let value = info["hardwareIdentifier"] as? String {
            hardwareIdentifier = value
        }

        if let value = info["systemVersion"] as? String {
            watchOSVersion = value
        }

        if let value = info["build"] as? String {
            buildVersion = value
        }

        if let timestamp = info["timestamp"] as? TimeInterval {
            lastUpdate = Date(timeIntervalSince1970: timestamp)
        }

        print("[WC] Device information updated")
    }

    // MARK: - Store received backup

    private static func storeBackup(
        data receivedData: Data,
        metadata: [String: Any]?
    ) throws -> BackupRecord {

        guard !receivedData.isEmpty else {
            throw NSError(
                domain: "HermesCompanion.Backup",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Le fichier reçu est vide."
                ]
            )
        }

        try validateBackup(receivedData)

        let receivedHash = sha256(receivedData)
        if let expectedHash = metadata?["sha256"] as? String,
           expectedHash.lowercased() != receivedHash {
            throw NSError(domain: "HermesCompanion.Backup", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "The received backup does not match the watch's checksum."])
        }
        // Session activation can resend the same original backup. Reuse an
        // existing record only after confirming the stored bytes still match.
        for record in try loadManifest() where record.sha256 == receivedHash {
            let existingURL = try backupURL(for: record.fileName)
            if (try? Data(contentsOf: existingURL)) == receivedData { return record }
        }
        let directory = try backupDirectory()

        let identifier = UUID()
        let fileName = "OriginalGestalt-\(identifier.uuidString).plist"
        let destinationURL = directory.appendingPathComponent(fileName)

        // Write the received data directly to the iPhone backup directory.
        try receivedData.write(to: destinationURL, options: .atomic)

        // Verify the stored copy.
        let storedData = try Data(contentsOf: destinationURL)

        guard storedData == receivedData,
              sha256(storedData) == receivedHash else {

            try? FileManager.default.removeItem(at: destinationURL)

            throw NSError(
                domain: "HermesCompanion.Backup",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "La sauvegarde copiée ne correspond pas au fichier reçu."
                ]
            )
        }

        try FileManager.default.setAttributes(
            [
                .protectionKey:
                    FileProtectionType.completeUntilFirstUserAuthentication
            ],
            ofItemAtPath: destinationURL.path
        )

        let deviceIdentifier =
            metadata?["hardwareIdentifier"] as? String ?? "Unknown"

        let transferDate =
            (metadata?["transferDate"] as? TimeInterval)
            .map { Date(timeIntervalSince1970: $0) } ?? Date()

        let record = BackupRecord(
            id: identifier,
            fileName: fileName,
            date: transferDate,
            size: storedData.count,
            sha256: receivedHash,
            deviceIdentifier: deviceIdentifier,
            hashOrigin: metadata?["sha256"] == nil ? "iPhone baseline (legacy transfer)" : "Verified watch transfer"
        )

        var records = try loadManifest()
        records.append(record)
        records.sort { $0.date > $1.date }

        do {
            try saveManifest(records)
        } catch {
            try? FileManager.default.removeItem(at: destinationURL)
            throw error
        }

        print("[WC] Backup stored successfully")
        print("[WC] Destination: \(destinationURL.path)")
        print("[WC] Size: \(storedData.count) bytes")
        print("[WC] SHA256: \(receivedHash)")

        return record
    }

    // MARK: - External import

    func importBackup(from sourceURL: URL) throws -> ImportResult {
        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        guard sourceURL.pathExtension.lowercased() == "plist" else {
            throw NSError(
                domain: "HermesCompanion.Import",
                code: 10,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Le fichier doit être au format .plist."
                ]
            )
        }

        let data = try Data(contentsOf: sourceURL)
        try Self.validateBackup(data)

        let importedHash = Self.sha256(data)
        let records = try Self.loadManifest()

        // Reject any backup already present in the history.
        guard !records.contains(where: {
            $0.sha256.caseInsensitiveCompare(importedHash) == .orderedSame
        }) else {
            return .duplicate
        }

        let directory = try Self.backupDirectory()
        let identifier = UUID()
        let fileName = "OriginalGestalt-\(identifier.uuidString).plist"
        let destinationURL = directory.appendingPathComponent(fileName)

        try data.write(to: destinationURL, options: .atomic)

        let storedData = try Data(contentsOf: destinationURL)

        guard storedData == data,
              Self.sha256(storedData) == importedHash else {
            try? FileManager.default.removeItem(at: destinationURL)

            throw NSError(
                domain: "HermesCompanion.Import",
                code: 11,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "La vérification de la copie a échoué."
                ]
            )
        }

        try FileManager.default.setAttributes(
            [
                .protectionKey:
                    FileProtectionType.completeUntilFirstUserAuthentication
            ],
            ofItemAtPath: destinationURL.path
        )

        let record = BackupRecord(
            id: identifier,
            fileName: fileName,
            date: Date(),
            size: storedData.count,
            sha256: importedHash,
            deviceIdentifier: "Import externe",
            hashOrigin: "External import"
        )

        var updatedRecords = records
        updatedRecords.append(record)
        updatedRecords.sort { $0.date > $1.date }

        do {
            try Self.saveManifest(updatedRecords)
        } catch {
            try? FileManager.default.removeItem(at: destinationURL)
            throw error
        }

        loadBackupHistory()

        print("[IMPORT] Backup imported: \(fileName)")
        print("[IMPORT] SHA256: \(importedHash)")

        return .imported(record)
    }

    // MARK: - Backup reception UI

    private func updateBackupInformation(_ record: BackupRecord) {
        loadBackupHistory()
        backupStatus = "Sauvegarde reçue et vérifiée"

        print("[WC] Backup successfully stored")
        print("[WC] File: \(record.fileName)")
        print("[WC] Size: \(record.formattedSize)")
        print("[WC] SHA256: \(record.sha256)")
    }

    // MARK: - Verification

    func verifyBackup(_ record: BackupRecord) -> VerificationResult {
        do {
            let url = try Self.backupURL(for: record.fileName)

            guard FileManager.default.fileExists(atPath: url.path) else {
                return .missing
            }

            let data = try Data(contentsOf: url)
            try Self.validateBackup(data)

            let currentHash = Self.sha256(data)

            guard currentHash == record.sha256 else {
                lastVerificationMessage =
                    "SHA-256 différent : le fichier a été modifié."

                return .invalid
            }

            lastVerificationMessage =
                "Intégrité confirmée : SHA-256 identique."

            return .valid

        } catch {
            lastVerificationMessage = error.localizedDescription
            return .error(error.localizedDescription)
        }
    }

    // MARK: - Export

    func exportURL(for record: BackupRecord) -> URL? {
        do {
            let url = try Self.backupURL(for: record.fileName)

            guard FileManager.default.fileExists(atPath: url.path) else {
                return nil
            }

            return url

        } catch {
            print("[WC] Export URL error: \(error)")
            return nil
        }
    }

    // MARK: - Latest backup

    var latestBackup: BackupRecord? {
        backups.sorted { $0.date > $1.date }.first
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            print("[WC] iPhone activation state: \(activationState.rawValue)")

            if let error {
                print("[WC] Activation error: \(error.localizedDescription)")
                return
            }

            self.updateStatus(session)

            guard activationState == .activated else {
                return
            }

            let context = session.receivedApplicationContext

            if !context.isEmpty {
                self.updateDeviceInformation(context)
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        Task { @MainActor in
            print("[WC] New application context received")
            self.updateDeviceInformation(applicationContext)
            self.updateStatus(session)
        }
    }

    // MARK: - Receive transferred file

    nonisolated func session(
        _ session: WCSession,
        didReceive file: WCSessionFile
    ) {
        print("[WC] Backup file received")

        // WCSession removes its temporary file after this delegate returns.
        do {
            let data = try Data(contentsOf: file.fileURL)
            let metadata = file.metadata
            Task { @MainActor in
                do {
                    let record = try Self.storeBackup(data: data, metadata: metadata)
                    self.updateBackupInformation(record)
                } catch {
                    self.backupStatus = "Backup rejected: \(error.localizedDescription)"
                }
            }
        } catch {
            print("[WC] Could not read transferred backup: \(error.localizedDescription)")
        }
    }

    nonisolated func sessionReachabilityDidChange(
        _ session: WCSession
    ) {
        Task { @MainActor in
            self.updateStatus(session)
        }
    }

    nonisolated func sessionDidBecomeInactive(
        _ session: WCSession
    ) {
        print("[WC] Session became inactive")
    }

    nonisolated func sessionDidDeactivate(
        _ session: WCSession
    ) {
        print("[WC] Session deactivated")
        session.activate()
    }
    
    // MARK: - Send external backup to Apple Watch

    func transferBackupToWatch(at fileURL: URL) -> Bool {
        guard let session else {
            print("[WC] No WatchConnectivity session")
            return false
        }

        guard session.activationState == .activated else {
            print("[WC] Session is not activated")
            return false
        }

        guard session.isPaired, session.isWatchAppInstalled else {
            print("[WC] Apple Watch is not paired or app is not installed")
            return false
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("[WC] Selected backup file does not exist")
            return false
        }

        do {
            let data = try Data(contentsOf: fileURL)

            let plist = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            )

            guard let dictionary = plist as? [String: Any],
                  dictionary["CacheExtra"] is [String: Any],
                  dictionary["CacheData"] is Data else {
                print("[WC] Invalid MobileGestalt backup")
                return false
            }

            let hash = SHA256.hash(data: data)
                .map { String(format: "%02x", $0) }
                .joined()
            guard let record = backups.first(where: { $0.fileName == fileURL.lastPathComponent }),
                  record.sha256.caseInsensitiveCompare(hash) == .orderedSame else {
                print("[WC] Backup differs from its saved checksum; transfer refused")
                return false
            }

            let metadata: [String: Any] = [
                "type": "externalGestaltRestoreCandidate",
                "fileName": fileURL.lastPathComponent,
                "sha256": hash,
                "transferDate": Date().timeIntervalSince1970,
                "source": "HermesCompanion"
            ]

            let transfer = session.transferFile(
                fileURL,
                metadata: metadata
            )

            print("[WC] External backup transfer queued")
            print("[WC] File: \(fileURL.lastPathComponent)")
            print("[WC] SHA256: \(hash)")
            print("[WC] Is transferring: \(transfer.isTransferring)")

            return true

        } catch {
            print("[WC] Backup transfer preparation failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func refreshConnectionStatus() {
        guard let session else {
            print("[WC] No active WatchConnectivity session")
            return
        }

        guard session.activationState == .activated else {
            print("[WC] Session not activated, requesting activation")
            session.activate()
            return
        }

        updateStatus(session)

        print("[WC] Connection status refreshed")
    }
    
}

