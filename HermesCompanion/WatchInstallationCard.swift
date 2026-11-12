import SwiftUI

struct WatchInstallationCard: View {
    @ObservedObject var watchManager: WatchConnectivityManager

    // MARK: - Watch installation status

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 10) {
                Image(systemName: installationIcon)
                    .font(.title2)
                    .foregroundStyle(installationColor)

                Text(installationTitle)
                    .font(.headline)

                Spacer()

                Circle()
                    .fill(installationColor)
                    .frame(width: 9, height: 9)
            }

            Text(installationMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if watchManager.isPaired && !watchManager.isWatchAppInstalled {
                Divider()

                Label(
                    "How to install HermesEnabler",
                    systemImage: "applewatch"
                )
                .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Label("Open the Watch app on your iPhone.", systemImage: "1.circle")
                    Label("Find HermesEnabler in the list of apps.", systemImage: "2.circle")
                    Label("Tap Install.", systemImage: "3.circle")
                    Label("Once installed, open the app on your Apple Watch.", systemImage: "4.circle")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

            } else if watchManager.isPaired && watchManager.isWatchAppInstalled && !watchManager.isReachable {
                Divider()

                Label(
                    "Open HermesEnabler on your Apple Watch.",
                    systemImage: "hand.tap"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    private var installationTitle: LocalizedStringKey {
        if !watchManager.isPaired {
            return "Apple Watch not paired"
        }

        if !watchManager.isWatchAppInstalled {
            return "Installation required"
        }

        if watchManager.isReachable {
            return "HermesEnabler is connected"
        }

        return "App installed"
    }

    private var installationMessage: LocalizedStringKey {
        if !watchManager.isPaired {
            return "Pair your Apple Watch with this iPhone to use HermesEnabler."
        }

        if !watchManager.isWatchAppInstalled {
            return "HermesEnabler is installed on the iPhone, but the watch app is not installed."
        }

        if watchManager.isReachable {
            return "Your Apple Watch is connected to HermesCompanion."
        }

        return "The watch app is installed but is not connected. Open HermesEnabler on your Apple Watch."
    }

    private var installationIcon: String {
        if !watchManager.isPaired {
            return "applewatch.slash"
        }

        if !watchManager.isWatchAppInstalled {
            return "arrow.down.app"
        }

        if watchManager.isReachable {
            return "checkmark.circle.fill"
        }

        return "applewatch"
    }

    private var installationColor: Color {
        if !watchManager.isPaired {
            return .secondary
        }

        if !watchManager.isWatchAppInstalled {
            return .orange
        }

        if watchManager.isReachable {
            return .green
        }

        return .orange
    }

    private var watchStatusText: String {
        if !watchManager.isPaired {
            return "No watch paired"
        }

        if !watchManager.isWatchAppInstalled {
            return "App not installed"
        }

        if watchManager.isReachable {
            return "Connected"
        }

        return "Installed, not reachable"
    }

    private var watchStatusColor: Color {
        if watchManager.isReachable {
            return .green
        }

        if watchManager.isPaired {
            return .orange
        }

        return .secondary
    }

}
