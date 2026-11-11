//
//  WatchConnectivityManager.swift
//  HermesEnabler2
//
//  Created by Metalnodeug on 11/11/2026.
//

import Foundation
import WatchKit
import WatchConnectivity
import Darwin

final class WatchConnectivityManager: NSObject, WCSessionDelegate {

    static let shared = WatchConnectivityManager()

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func sendDeviceInformation() {
        let session = WCSession.default

        guard session.activationState == .activated else { return }

        let device = WKInterfaceDevice.current()

        var information: [String: Any] = [
            "deviceName": device.name,
            "model": device.model,
            "localizedModel": device.localizedModel,
            "systemName": device.systemName,
            "systemVersion": device.systemVersion,
            "hardwareIdentifier": hardwareIdentifier(),
            "timestamp": Date().timeIntervalSince1970
        ]

        if let build = systemBuild() {
            information["build"] = build
        }

        do {
            try session.updateApplicationContext(information)
        } catch {
            print("WatchConnectivity error: \(error)")
        }
    }

    private func hardwareIdentifier() -> String {
        return sysctlValue("hw.machine") ?? "Unknown"
    }

    private func systemBuild() -> String? {
        return sysctlValue("kern.osversion")
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
        if activationState == .activated {
            sendDeviceInformation()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            sendDeviceInformation()
        }
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        print("Message received from iPhone: \(message)")
    }
}
