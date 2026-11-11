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
    @Published var isPaired = false
    @Published var isWatchAppInstalled = false
    @Published var isReachable = false

    @Published var deviceName = "Apple Watch"
    @Published var hardwareIdentifier = "Unknown"
    @Published var watchOSVersion = "Unknown"
    @Published var buildVersion = "Unknown"

    private var session: WCSession?

    override init() {
        super.init()

        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        self.session = session
        session.delegate = self
        session.activate()
    }

    private func updateStatus(_ session: WCSession) {
        isPaired = session.isPaired
        isWatchAppInstalled = session.isWatchAppInstalled
        isReachable = session.isReachable
    }

    private func updateDeviceInformation(_ info: [String: Any]) {
        if let value = info["deviceName"] as? String {
            deviceName = value
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
    }
}

extension WatchConnectivityManager: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.updateStatus(session)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        Task { @MainActor in
            self.updateDeviceInformation(applicationContext)
            self.updateStatus(session)
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.updateStatus(session)
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
