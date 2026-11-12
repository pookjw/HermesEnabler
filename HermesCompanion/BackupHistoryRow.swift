import SwiftUI

// MARK: - Backup History Row

struct BackupHistoryRow: View {

    let record: WatchConnectivityManager.BackupRecord

    var body: some View {

        HStack(spacing: 13) {

            Image(systemName: "doc.zipper")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 42, height: 42)
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 12)
                )

            VStack(alignment: .leading, spacing: 5) {

                Text(record.date.formatted(
                    date: .abbreviated,
                    time: .shortened
                ))
                .font(.subheadline.weight(.semibold))

                Text(NSLocalizedString(record.hashOrigin, comment: "Backup source"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(record.formattedSize)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 5)
    }
}
