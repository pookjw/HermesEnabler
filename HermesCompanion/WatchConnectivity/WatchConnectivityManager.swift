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

    @Published var hasExternalBackup = false
    @Published var backupFileName = "No backup"
    @Published var backupSize = "Unknown"
    @Published var backupSHA256 = "Unknown"
    @Published var backupDate: Date?
    @Published var backupDeviceIdentifier = "Unknown"
    @Published var backupStatus = "No backup received"

    private var session: WCSession?

    // MARK: - Initialization

    override init() {
        super.init()

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

    // MARK: - Backup reception

    private func updateBackupInformation(
        fileName: String,
        size: Int,
        hash: String,
        date: Date,
        deviceIdentifier: String
    ) {
        hasExternalBackup = true
        backupFileName = fileName
        backupSize = ByteCountFormatter.string(
            fromByteCount: Int64(size),
            countStyle: .file
        )
        backupSHA256 = hash
        backupDate = date
        backupDeviceIdentifier = deviceIdentifier
        backupStatus = "Backup received and verified"

        print("[WC] Backup successfully stored")
        print("[WC] File: \(fileName)")
        print("[WC] Size: \(backupSize)")
        print("[WC] SHA256: \(hash)")
    }

    // MARK: - Backup storage

    nonisolated private static func storeBackup(
        from sourceURL: URL,
        metadata: [String: Any]?
    ) throws -> (String, Int, String, Date, String) {

        let fileManager = FileManager.default

        // Read and validate the original plist.
        let originalData = try Data(contentsOf: sourceURL)

        let plist = try PropertyListSerialization.propertyList(
            from: originalData,
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

        // Calculate SHA-256.
        let digest = SHA256.hash(data: originalData)
        let hash = digest.map {
            String(format: "%02x", $0)
        }.joined()

        // Independent iPhone storage.
        let applicationSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let backupDirectory = applicationSupport
            .appendingPathComponent("HermesEnabler", isDirectory: true)
            .appendingPathComponent("Backups", isDirectory: true)

        try fileManager.createDirectory(
            at: backupDirectory,
            withIntermediateDirectories: true
        )

        // Never overwrite an existing backup.
        let identifier = UUID().uuidString

        let fileName = "OriginalGestalt-\(identifier).plist"

        let destinationURL = backupDirectory
            .appendingPathComponent(fileName)

        try fileManager.copyItem(
            at: sourceURL,
            to: destinationURL
        )

        // Verify the stored copy.
        let storedData = try Data(contentsOf: destinationURL)

        guard storedData == originalData else {
            try? fileManager.removeItem(at: destinationURL)

            throw NSError(
                domain: "HermesCompanion.Backup",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Stored backup does not match received file."
                ]
            )
        }

        // Verify the SHA-256 of the stored copy.
        let storedHash = SHA256.hash(data: storedData)
            .map { String(format: "%02x", $0) }
            .joined()

        guard storedHash == hash else {
            try? fileManager.removeItem(at: destinationURL)

            throw NSError(
                domain: "HermesCompanion.Backup",
                code: 3,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "SHA-256 verification failed."
                ]
            )
        }

        try fileManager.setAttributes(
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

        return (
            fileName,
            storedData.count,
            hash,
            transferDate,
            deviceIdentifier
        )
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

        do {
            let result = try Self.storeBackup(
                from: file.fileURL,
                metadata: file.metadata
            )

            Task { @MainActor in
                self.updateBackupInformation(
                    fileName: result.0,
                    size: result.1,
                    hash: result.2,
                    date: result.3,
                    deviceIdentifier: result.4
                )
            }

        } catch {
            print("[WC] Backup reception error: \(error.localizedDescription)")

            Task { @MainActor in
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
