import SwiftUI

struct IntelligenceView: View {
    let model: ContentModel

    var body: some View {
        List {
            Section("Region") {
                NavigationLink { RegionCodeOptionsView(model: model) } label: {
                    optionRow("Region Code", value: model.selectedRegionCodeTitle)
                }
                NavigationLink { SalesRegionOptionsView(model: model) } label: {
                    optionRow("Sales Region", value: model.selectedSalesRegionTitle)
                }
            }
            Section("Watch Capabilities") {
                Toggle("Apple Intelligence / Siri AI", isOn: Binding(get: { model.appleIntelligenceEnabled }, set: { model.perform(.appleIntelligence($0)) }))
                Toggle("On-Device Siri", isOn: Binding(get: { model.onDeviceSiriEnabled }, set: { model.perform(.onDeviceSiri($0)) }))
                Toggle("Audio Intelligence", isOn: Binding(get: { model.audioIntelligenceEnabled }, set: { model.perform(.audioIntelligence($0)) }))
            }
            Text("Siri AI needs watchOS 27, a supported watch and a paired Apple Intelligence iPhone. Audio Intelligence is for Series 12 / Ultra 4 hardware. These flags cannot add missing hardware or bypass service eligibility.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Siri & Intelligence")
        .disabled(!model.hasBackup)
    }
}
