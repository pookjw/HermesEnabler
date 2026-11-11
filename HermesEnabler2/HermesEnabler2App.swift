//
//  HermesEnabler2App.swift
//  HermesEnabler2
//
//  Created by Jinwoo Kim on 11/9/26.
//

import SwiftUI

@main
struct HermesEnabler2App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    let args = ProcessInfo.processInfo.arguments
                    if args.contains("--ultra-diagnostics") { _ = BQWriteUltraDiagnostics() }
                    if args.contains("--compatibility-report") { _ = BQWriteCompatibilityReport() }
                    if args.contains("--snapshot-probe") { BQRunSnapshotProbe() }
                }
        }
    }
}
