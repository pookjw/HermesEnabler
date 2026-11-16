import SwiftUI

/// Experimental viewer for genuine Apple-installed NanoTimeKit FaceViews.
/// This is an in-app view, NOT a system ClockFace or a Face Gallery unlock.
struct OriginalHermesView: View {
    @Environment(\.isLuminanceReduced) private var reducedLuminance
    @State private var presentingOriginal = false
    @State private var message = "Choose an Apple original face."

    private let names = [
        "Hermès Circulaire", "Hermès", "Hermès Radial",
        "Hermès Circuit H", "Hermès Lucky Horse", "Hermès Faubourg Party"
    ]

    var body: some View {
        Group {
            if presentingOriginal {
                // Remove the scrolling SwiftUI menu while the native Apple
                // controller is mounted; never draw a replacement clock.
                Color.clear.ignoresSafeArea().accessibilityHidden(true)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        Text("APPLE ORIGINAL").font(.headline)
                        Text("Experimental in-app viewer. It does not enable the system Face Gallery or replace ClockFace.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        ForEach(names.indices, id: \.self) { index in
                            Button(names[index]) {
                                let result = BQOriginalHermes.presentFace(at: index) ?? "Original Apple FaceView unavailable"
                                if result == "native-face-mounted" {
                                    presentingOriginal = true
                                } else {
                                    message = result
                                }
                            }
                            .font(.caption2)
                        }
                        Text(message).font(.caption2)
                        Text("Long-press the original face to return.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                }
            }
        }
        .navigationTitle("Original Hermès")
        .onChange(of: reducedLuminance) { _, reduced in
            if presentingOriginal {
                BQOriginalHermes.updateActualReducedLuminance(reduced)
            }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: Notification.Name("BQOriginalHermesDismissed")
        )) { _ in
            presentingOriginal = false
        }
        .onDisappear {
            BQOriginalHermes.dismissFace()
        }
    }
}
