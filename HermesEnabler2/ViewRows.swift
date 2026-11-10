import SwiftUI

func optionRow(_ title: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
        Text(title)
        Text(value).font(.footnote).foregroundStyle(.secondary)
    }
}

func selectionRow(_ title: String, selected: Bool) -> some View {
    HStack {
        Text(title)
        Spacer()
        if selected { Image(systemName: "checkmark") }
    }
}
