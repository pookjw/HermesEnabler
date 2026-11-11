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
