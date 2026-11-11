//
//  WatchConnectivityManager.swift
//  HermesEnabler2
//
//  Created by Metalnodeug on 11/11/2026.
//

import Foundation
import WatchConnectivity
import Combine

@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {

    // MARK: - Connection status

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

    // MARK: - Internal session

    private var session: WCSession?

    // MARK: - Initialization

    override init() {
        super.init()

        guard WCSession.isSupported() else {
            print("[WC] WatchConnectivity is not supported")
            return
        }

        let session = WCSession.default
        self.session = session

        session.delegate = self
        session.activate()

        print("[WC] iPhone session activation requested")
    }

    // MARK: - Status

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

        print("[WC] Device information updated successfully")
    }

    // MARK: - Request information

    func requestDeviceInformation() {
        guard let session,
              session.activationState == .activated else {
            print("[WC] Cannot request information: session not activated")
            return
        }

        guard session.isReachable else {
            print("[WC] Watch is not currently reachable")
            return
        }

        let message: [String: Any] = [
            "request": "deviceInformation"
        ]

        session.sendMessage(
            message,
            replyHandler: { reply in
                print("[WC] Reply received: \(reply)")
            },
            errorHandler: { error in
                print("[WC] Message error: \(error.localizedDescription)")
            }
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
                print("[WC] Existing application context found")
                self.updateDeviceInformation(context)
            } else {
                print("[WC] No application context available yet")
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
