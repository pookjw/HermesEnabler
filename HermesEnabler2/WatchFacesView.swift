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
            if BQSupportsLargerUltraFaceLayout() {
                Section {
                    if model.ultraFacesEnabled {
                        Picker("Ultra Face Layout", selection: Binding(
                            get: { model.ultraFaceClass },
                            set: { if $0 != model.ultraFaceClass { model.perform(.ultraFaceClass($0)) } }
                        )) {
                            Text("Class 29").tag(29)
                            Text("Class 38").tag(38)
                        }
                    } else {
                        LabeledContent("Ultra Face Layout", value: "Not Active")
                    }
                } footer: {
                    Text("A larger layout may not fit your screen and may affect other faces and complications. Changes apply immediately; restart the watch to reload them.")
                }
            }
        }
        .navigationTitle("Watch Faces")
    }
}
