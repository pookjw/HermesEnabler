import SwiftUI

struct ResolutionOptionsView: View {
    let model: ContentModel

    var body: some View {
        List {
            Section("Current Reported Size") {
                Text(model.screenWidth > 0 ? "\(model.screenWidth) × \(model.screenHeight) pixels" : LocalizedStringKey("Could not read dimensions"))
                if model.resolutionOverridden {
                    Button("Restore Original Size") { model.perform(.resolution(0, 0)) }
                }
            }
            Section("Presets") {
                ForEach(ContentModel.resolutionPresets) { preset in
                    Button { model.perform(.resolution(preset.width, preset.height)) } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            selectionRow(preset.title, selected: model.screenWidth == preset.width && model.screenHeight == preset.height)
                            Text("\(preset.width) × \(preset.height) px")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Text("Changes the MobileGestalt reported dimensions, not physical pixels. A different size can clip watchOS content. Restart the watch after applying; restore the original size if the layout worsens.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Screen Resolution")
        .disabled(!model.hasBackup)
    }
}
