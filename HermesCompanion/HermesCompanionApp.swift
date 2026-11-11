import SwiftUI

@main
struct HermesCompanionApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {

    @State private var selectedAction: BackupAction?

    private let deviceName = "Apple Watch Ultra 2"
    private let watchOSVersion = "watchOS 27.3"
    private let buildVersion = "24S5284h"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Header
                header

                // Connected device
                deviceSection

                Divider()

                // Backup status
                backupSection

                Divider()

                // Actions
                actionsSection

                // Footer
                Text("HermesEnabler Companion")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(24)
            .frame(maxWidth: 760)
            .background(Color(uiColor: .systemBackground))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 1)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: .systemBackground))
        .alert(item: $selectedAction) { action in
            Alert(
                title: Text(action.title),
                message: Text(action.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            Text("HermesEnabler")
                .font(.system(size: 27, weight: .bold))

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)

                Text("Connecté")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(.green.opacity(0.12), in: Capsule())
        }
    }

    // MARK: - Device

    private var deviceSection: some View {
        HStack(spacing: 20) {

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .frame(width: 108, height: 108)

                Image(systemName: "applewatch")
                    .font(.system(size: 53, weight: .light))
                    .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: 7) {

                Text(deviceName)
                    .font(.system(size: 20, weight: .semibold))

                Text("\(watchOSVersion) · \(buildVersion)")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)

                Text("Sauvegarde disponible")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.green)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Backup Section

    private var backupSection: some View {
        VStack(alignment: .leading, spacing: 24) {

            Text("MobileGestalt Backup")
                .font(.system(size: 21, weight: .bold))

            BackupStatusRow(
                title: "Original Backup",
                subtitle: "Sauvegarde initiale",
                status: "Validée",
                color: .green
            )

            BackupStatusRow(
                title: "External Backup",
                subtitle: "Copie exportée",
                status: "Disponible",
                color: .green
            )
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 22) {

            BackupActionRow(
                icon: "arrow.down.to.line",
                title: "Export Original Backup",
                color: .green
            ) {
                selectedAction = .export
            }

            BackupActionRow(
                icon: "arrow.up.to.line",
                title: "Import Backup"
            ) {
                selectedAction = .import
            }

            BackupActionRow(
                icon: "clock.arrow.circlepath",
                title: "Backup History"
            ) {
                selectedAction = .history
            }

            BackupActionRow(
                icon: "checkmark.shield",
                title: "Verify Backup Integrity"
            ) {
                selectedAction = .verify
            }
        }
    }
}

// MARK: - Backup Status Row

struct BackupStatusRow: View {

    let title: String
    let subtitle: String
    let status: String
    let color: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.system(size: 19, weight: .semibold))

                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(status)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(color.opacity(0.12), in: Capsule())
        }
    }
}

// MARK: - Backup Action Row

struct BackupActionRow: View {

    let icon: String
    let title: String
    var color: Color = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Actions

enum BackupAction: String, Identifiable {

    case export
    case `import`
    case history
    case verify

    var id: String { rawValue }

    var title: String {
        switch self {
        case .export: return "Export Backup"
        case .import: return "Import Backup"
        case .history: return "Backup History"
        case .verify: return "Verify Integrity"
        }
    }

    var message: String {
        "Cette fonctionnalité sera connectée au moteur de sauvegarde HermesEnabler."
    }
}
