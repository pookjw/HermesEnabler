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
    @Published var backupStatus = "No backup received"
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

    // MARK: - History loading and migration

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

                    let date =
                        attributes[.creationDate] as? Date ?? Date()

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

                    print(
                        "[WC] Initial baseline created for \(record.fileName)"
                    )

                } catch {
                    print(
                        "[WC] Existing backup migration failed: \(error)"
                    )
                }
            }

            records.sort { $0.date > $1.date }

            try Self.saveManifest(records)

            backups = records

            backupStatus = records.isEmpty
                ? "No backup received"
                : "\(records.count) backup(s) stored"

            print("[WC] Backup history loaded: \(records.count)")

        } catch {
            print("[WC] History loading error: \(error.localizedDescription)")
            backupStatus = "History loading failed"
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
                        "Invalid MobileGestalt backup structure."
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
        print("[WC] Received device information: \(info)")

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
        from sourceURL: URL,
        metadata: [String: Any]?
    ) throws -> BackupRecord {

        let originalData = try Data(contentsOf: sourceURL)

        try validateBackup(originalData)

        let originalHash = sha256(originalData)

        let directory = try backupDirectory()

        let identifier = UUID()
        let fileName = "OriginalGestalt-\(identifier.uuidString).plist"

        let destinationURL = directory
            .appendingPathComponent(fileName)

        // Create an independent copy. Never overwrite.
        try FileManager.default.copyItem(
            at: sourceURL,
            to: destinationURL
        )

        let storedData = try Data(contentsOf: destinationURL)

        guard storedData == originalData else {
            try? FileManager.default.removeItem(at: destinationURL)

            throw NSError(
                domain: "HermesCompanion.Backup",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Stored backup does not match received file."
                ]
            )
        }

        let storedHash = sha256(storedData)

        guard storedHash == originalHash else {
            try? FileManager.default.removeItem(at: destinationURL)

            throw NSError(
                domain: "HermesCompanion.Backup",
                code: 3,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "SHA-256 verification failed."
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
            .map { Date(timeIntervalSince1970: $0) }
            ?? Date()

        let record = BackupRecord(
            id: identifier,
            fileName: fileName,
            date: transferDate,
            size: storedData.count,
            sha256: storedHash,
            deviceIdentifier: deviceIdentifier,
            hashOrigin: "Received and verified"
        )

        // Persist manifest without overwriting existing records.
        var records = try loadManifest()

        records.append(record)
        records.sort { $0.date > $1.date }

        try saveManifest(records)

        return record
    }

    // MARK: - Backup reception UI

    private func updateBackupInformation(_ record: BackupRecord) {
        loadBackupHistory()

        backupStatus = "Backup received and verified"

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
                    "SHA-256 mismatch: file has changed."

                return .invalid
            }

            lastVerificationMessage =
                "Integrity verified: SHA-256 matches."

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

        Task { @MainActor in
            do {
                let record = try Self.storeBackup(
                    from: file.fileURL,
                    metadata: file.metadata
                )

                self.updateBackupInformation(record)

            } catch {
                print(
                    "[WC] Backup reception error: \(error.localizedDescription)"
                )

                self.backupStatus =
                    "Backup rejected: \(error.localizedDescription)"
            }
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
}
