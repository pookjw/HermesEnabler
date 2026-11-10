import SwiftUI

struct WatchFacesView: View {
    let model: ContentModel

    var body: some View {
        List {
            Section {
                Toggle("Hermès", isOn: Binding(get: { model.hermesEnabled }, set: { model.perform(.hermes($0)) }))
                Toggle("Ultra Faces", isOn: Binding(get: { model.ultraFacesEnabled }, set: { model.perform(.ultraFaces($0)) }))
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Restart Carousel after changing a face capability.")
                    Text("If you enable Ultra Faces, you won't be able to use the Hermès Faubourg Party face.")
                }
            }
        }
        .navigationTitle("Watch Faces")
        .disabled(!model.hasBackup)
    }
}
