//
//  WatchConnectivityManager.swift
//  HermesEnabler2
//
//

import Foundation
import WatchKit
import WatchConnectivity
import Darwin
import CryptoKit

final class WatchConnectivityManager: NSObject, WCSessionDelegate {

    static let shared = WatchConnectivityManager()

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else {
            print("[WC] WatchConnectivity not supported")
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()

        print("[WC] Activation requested")
    }

    func sendDeviceInformation() {
        let session = WCSession.default

        guard session.activationState == .activated else {
            print("[WC] Session not activated")
            return
        }

        let device = WKInterfaceDevice.current()
        let hardware = hardwareIdentifier()
        let build = systemBuild()

        var information: [String: Any] = [
            "deviceName": device.name,
            "model": device.model,
            "localizedModel": device.localizedModel,
            "systemName": device.systemName,
            "systemVersion": device.systemVersion,
            "hardwareIdentifier": hardware,
            "timestamp": Date().timeIntervalSince1970
        ]

        if let build {
            information["build"] = build
        }

        print("[WC] Sending information: \(information)")

        do {
            try session.updateApplicationContext(information)
            print("[WC] Application context updated")
        } catch {
            print("[WC] Sending error: \(error.localizedDescription)")
        }
    }

    private func hardwareIdentifier() -> String {
        sysctlValue("hw.machine") ?? "Unknown"
    }

    private func systemBuild() -> String? {
        sysctlValue("kern.osversion")
    }

    private func sysctlValue(_ key: String) -> String? {
        var size = 0

        guard sysctlbyname(key, nil, &size, nil, 0) == 0,
              size > 0 else {
            return nil
        }

        var buffer = [CChar](repeating: 0, count: size)

        guard sysctlbyname(key, &buffer, &size, nil, 0) == 0 else {
            return nil
        }

        return String(cString: buffer)
    }

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        print("[WC] Activation state: \(activationState.rawValue)")

        if let error {
            print("[WC] Activation error: \(error.localizedDescription)")
            return
        }

        if activationState == .activated {
            sendDeviceInformation()

            if BQBackupExists() {
                print("[WC] Session activated, checking original backup transfer")
                transferOriginalBackup()
            } else {
                print("[WC] No original backup available yet")
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("[WC] Reachability: \(session.isReachable)")

        if session.isReachable {
            sendDeviceInformation()
        }
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        print("[WC] Message received: \(message)")
    }
    
    // MARK: - Receive external backup from iPhone

    func session(
        _ session: WCSession,
        didReceive file: WCSessionFile
    ) {
        let metadata = file.metadata ?? [:]

        guard let type = metadata["type"] as? String,
              type == "externalGestaltRestoreCandidate" else {
            print("[WC] Ignoring unrelated incoming file")
            return
        }

        print("[WC] External backup received from iPhone")

        do {
            let data = try Data(contentsOf: file.fileURL)

            guard !data.isEmpty else {
                print("[WC] Rejected empty backup")
                return
            }

            // Verify SHA-256 against the hash sent by the iPhone.
            guard let expectedHash = metadata["sha256"] as? String else {
                print("[WC] Missing SHA256 metadata. Backup rejected.")
                return
            }

            let actualHash = SHA256.hash(data: data)
                .map { String(format: "%02x", $0) }
                .joined()

            guard expectedHash.lowercased() == actualHash.lowercased() else {
                print("[WC] SHA256 mismatch. Backup rejected.")
                print("[WC] Expected: \(expectedHash)")
                print("[WC] Actual: \(actualHash)")
                return
            }

            // Validate the MobileGestalt property list structure.
            let propertyList = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            )

            guard let dictionary = propertyList as? [String: Any],
                  dictionary["CacheExtra"] is [String: Any],
                  dictionary["CacheData"] is Data else {
                print("[WC] Invalid MobileGestalt backup structure. Backup rejected.")
                return
            }

            let fileName = metadata["fileName"] as? String
                ?? file.fileURL.lastPathComponent

            print("[WC] External backup received and verified")
            print("[WC] File: \(fileName)")
            print("[WC] Size: \(data.count) bytes")
            print("[WC] SHA256: \(actualHash)")
            print("[WC] Waiting for user confirmation")

            // Ask ContentModel to display the import confirmation.
            // No file is stored in MGBackups at this stage.
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Notification.Name("HermesExternalBackupReceived"),
                    object: nil,
                    userInfo: [
                        "data": data,
                        "fileName": fileName,
                        "sha256": actualHash
                    ]
                )
            }

        } catch {
            print("[WC] Could not process received backup: \(error.localizedDescription)")
        }
    }

}

extension WatchConnectivityManager {
    
    func transferOriginalBackup() {
        let session = WCSession.default

        guard session.activationState == .activated else {
            print("[WC] Session not activated")
            return
        }

        guard BQBackupExists() else {
            print("[WC] Original backup does not exist")
            return
        }

        let sourceURL = URL(fileURLWithPath: BQBackupPath())

        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            print("[WC] Original backup file not found")
            return
        }

        let metadata: [String: Any] = [
            "type": "originalGestalt",
            "deviceName": WKInterfaceDevice.current().name,
            "hardwareIdentifier": hardwareIdentifier(),
            "watchOSVersion": WKInterfaceDevice.current().systemVersion,
            "build": systemBuild() ?? "Unknown",
            "transferDate": Date().timeIntervalSince1970
        ]
        
        print("[WC] Backup path: \(sourceURL.path)")
        print("[WC] Backup exists: \(FileManager.default.fileExists(atPath: sourceURL.path))")

        let transfer = session.transferFile(sourceURL, metadata: metadata)

        print("[WC] Original backup transfer queued")
        print("[WC] Transfer: \(transfer)")
        print("[WC] Transfer queued: \(transfer.isTransferring)")
    }
    
}
