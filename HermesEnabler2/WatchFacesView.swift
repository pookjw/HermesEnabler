import SwiftUI

struct WatchFacesView: View {
    let model: ContentModel
    @AppStorage("UltraScreenClass") private var ultraScreenClass = 29

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
            if BQSupportsLargerUltraFaceLayout() {
                Section {
                    Picker("Ultra Face Layout", selection: $ultraScreenClass) {
                        Text("Class 29").tag(29)
                        Text("Class 38").tag(38)
                    }
                    .disabled(model.ultraFacesEnabled)
                } footer: {
                    Text("A larger layout may not fit your screen and may affect other faces and complications. Turn off Ultra Faces before changing this option.")
                }
            }
        }
        .navigationTitle("Watch Faces")
    }
}
