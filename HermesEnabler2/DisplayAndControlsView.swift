import SwiftUI

struct DisplayAndControlsView: View {
    let model: ContentModel

    var body: some View {
        List {
            Section("Display") {
                Toggle("Always-On Display", isOn: Binding(get: { model.aodEnabled }, set: { model.perform(.aod($0)) }))
                Toggle("AOD 1 Hz", isOn: Binding(get: { model.aodSecondsEnabled }, set: { model.perform(.aodSeconds($0)) }))
                Toggle("AOD Vibrancy", isOn: Binding(get: { model.aodVibrancyEnabled }, set: { model.perform(.aodVibrancy($0)) }))
                Toggle("Periodic Ambient Light Updates", isOn: Binding(get: { model.periodicALSUpdatesEnabled }, set: { model.perform(.periodicALSUpdates($0)) }))
                NavigationLink { ResolutionOptionsView(model: model) } label: {
                    optionRow("Screen Resolution", value: model.screenWidth > 0 ? "\(model.screenWidth) × \(model.screenHeight) px" : "Unavailable")
                }
            }
            Section("Controls") {
                Toggle("Action Button", isOn: Binding(get: { model.actionButtonEnabled }, set: { model.perform(.actionButton($0)) }))
                Toggle("Double Tap", isOn: Binding(get: { model.doubleTapEnabled }, set: { model.perform(.doubleTap($0)) }))
                Toggle("On-Screen Keyboard", isOn: Binding(get: { model.watchKeyboardEnabled }, set: { model.perform(.watchKeyboard($0)) }))
                Toggle("Raise Wrist to Wake", isOn: Binding(get: { model.rotateToWakeEnabled }, set: { model.perform(.rotateToWake($0)) }))
            }
            Section("Voice") {
                Toggle("Raise to Speak", isOn: Binding(get: { model.raiseToSpeakEnabled }, set: { model.perform(.raiseToSpeak($0)) }))
                Toggle("Siri Listening Capability", isOn: Binding(get: { model.alwaysListeningEnabled }, set: { model.perform(.alwaysListening($0)) }))
            }
            Text("Some options require matching display, sensor, or audio hardware.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Display & Controls")
        .disabled(!model.hasBackup)
    }
}
