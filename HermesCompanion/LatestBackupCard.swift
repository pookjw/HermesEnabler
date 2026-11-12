import SwiftUI

struct LatestBackupCard: View {
    @ObservedObject var watchManager: WatchConnectivityManager

    // MARK: - Backup card

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            HStack {

                Text("MobileGestalt")
                    .font(.headline)

                Spacer()

                Text("\(watchManager.backups.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Divider()

            if let latest = watchManager.latestBackup {

                VStack(alignment: .leading, spacing: 7) {

                    Label(
                        "Latest Backup",
                        systemImage: "externaldrive.fill"
                    )
                    .font(.subheadline.weight(.medium))

                    Text(latest.date.formatted(
                        date: .abbreviated,
                        time: .shortened
                    ))
                    .font(.title3.weight(.semibold))

                    HStack {

                        Text(latest.formattedSize)

                        Spacer()

                        Text(NSLocalizedString(latest.hashOrigin, comment: "Backup source"))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

            } else {

                ContentUnavailableView(
                    "No Backups",
                    systemImage: "externaldrive",
                    description: Text(
                        "Import a file or receive a backup from your Apple Watch."
                    )
                )
                .frame(minHeight: 150)
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
