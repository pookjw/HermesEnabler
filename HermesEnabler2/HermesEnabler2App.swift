//
//  HermesEnabler2App.swift
//  HermesEnabler2
//
//  Created by Jinwoo Kim on 11/9/26.
//

import SwiftUI

@main
struct HermesEnabler2App: App {
    init() {
        WatchConnectivityManager.shared.activate()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
