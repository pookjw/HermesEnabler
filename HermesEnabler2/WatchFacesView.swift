import SwiftUI

struct WatchFacesView: View {
    let model: ContentModel

    var body: some View {
        List {
            Section {
                Toggle("Hermès", isOn: Binding(get: { model.hermesEnabled }, set: { model.perform(.hermes($0)) }))
                Toggle("Ultra Faces", isOn: Binding(get: { model.ultraFacesEnabled }, set: { model.perform(.ultraFaces($0)) }))
            } footer: {
                Text("Restart Carousel after changing a face capability.")
            }
        }
        .navigationTitle("Watch Faces")
        .disabled(!model.hasBackup)
    }
}
