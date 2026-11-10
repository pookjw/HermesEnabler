import SwiftUI

@main
struct HermesCompanionApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 16) {
                Image(systemName: "applewatch")
                    .font(.system(size: 56))
                Text("HermesEnabler")
                    .font(.title.bold())
                Text("Open HermesEnabler on your Apple Watch. If it is not installed, open the Watch app on your iPhone and install it from Available Apps.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
        }
    }
}
