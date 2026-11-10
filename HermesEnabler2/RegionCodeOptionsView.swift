import SwiftUI

struct RegionCodeOptionsView: View {
    let model: ContentModel

    var body: some View {
        List {
            Text("Changes RegionCode only. It leaves the sales-region suffix unchanged.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Section("Choose Region Code") {
                ForEach(ContentModel.regionOptions) { option in
                    Button { model.perform(.regionCode(option.regionCode)) } label: {
                        selectionRow(option.title, selected: model.regionCodeSelection == option.regionCode)
                    }
                }
            }
        }
        .navigationTitle("Region Code")
        .disabled(!model.hasBackup)
    }

}
