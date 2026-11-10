import SwiftUI

struct SalesRegionOptionsView: View {
    let model: ContentModel

    var body: some View {
        List {
            Text("Changes the sales-region suffix only. It may cause factory-information tools to report a mismatch.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Section("Choose Sales Region") {
                ForEach(ContentModel.regionOptions) { option in
                    Button { model.perform(.salesRegion(option.salesSuffix)) } label: {
                        selectionRow(option.title, selected: model.salesRegionSelection == option.salesSuffix)
                    }
                }
            }
        }
        .navigationTitle("Sales Region")
        .disabled(!model.hasBackup)
    }

}
