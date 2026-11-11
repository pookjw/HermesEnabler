import SwiftUI

func optionRow(_ title: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
        Text(LocalizedStringKey(title))
        Text(LocalizedStringKey(value)).font(.footnote).foregroundStyle(.secondary)
    }
}

func selectionRow(_ title: String, selected: Bool) -> some View {
    HStack {
        Text(LocalizedStringKey(title))
        Spacer()
        if selected { Image(systemName: "checkmark") }
    }
}
