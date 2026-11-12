import SwiftUI

struct WatchDeviceCard: View {
    @ObservedObject var watchManager: WatchConnectivityManager

    // MARK: - Watch card

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 14) {

                Image(systemName: "applewatch")
                    .font(.system(size: 34, weight: .light))
                    .frame(width: 58, height: 58)
                    .background(
                        Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 16)
                    )

                VStack(alignment: .leading, spacing: 5) {

                    Text(watchManager.deviceName)
                        .font(.headline)

                    Text(watchManager.model == "Unknown" ? String(localized: "Unknown") : watchManager.model)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if watchManager.watchOSVersion != "Unknown" {
                Text(
                    "watchOS \(watchManager.watchOSVersion) · \(watchManager.buildVersion)"
                )
                .font(.caption)
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

}
