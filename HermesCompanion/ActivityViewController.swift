import SwiftUI
import UIKit

// MARK: - Share Item

struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - Native iOS Share Sheet

struct ActivityViewController: UIViewControllerRepresentable {

    let activityItems: [Any]

    func makeUIViewController(
        context: Context
    ) -> UIActivityViewController {

        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ controller: UIActivityViewController,
        context: Context
    ) { }
}
