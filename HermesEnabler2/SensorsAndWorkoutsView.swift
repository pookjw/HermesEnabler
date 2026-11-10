import SwiftUI

struct SensorsAndWorkoutsView: View {
    let model: ContentModel

    var body: some View {
        List {
            Section("Sensors") {
                Toggle("Depth Sensor", isOn: Binding(get: { model.depthEnabled }, set: { model.perform(.depth($0)) }))
                Toggle("Absolute Altimeter", isOn: Binding(get: { model.absoluteAltimeterEnabled }, set: { model.perform(.absoluteAltimeter($0)) }))
                Toggle("Always-On Compass", isOn: Binding(get: { model.alwaysOnCompassEnabled }, set: { model.perform(.alwaysOnCompass($0)) }))
                Toggle("Compass Orienteering", isOn: Binding(get: { model.compassOrienteeringEnabled }, set: { model.perform(.compassOrienteering($0)) }))
            }
            Section("Health & Workouts") {
                Toggle("Continuous Heart Rate", isOn: Binding(get: { model.continuousHeartRateEnabled }, set: { model.perform(.continuousHeartRate($0)) }))
                Toggle("Noise Exposure", isOn: Binding(get: { model.environmentalDosimetryEnabled }, set: { model.perform(.environmentalDosimetry($0)) }))
                Toggle("Battery Information", isOn: Binding(get: { model.batteryInformationEnabled }, set: { model.perform(.batteryInformation($0)) }))
                Toggle("Swimming Workouts", isOn: Binding(get: { model.swimmingWorkoutsEnabled }, set: { model.perform(.swimmingWorkouts($0)) }))
            }
            Text("Capability flags do not add missing sensors or override Health permissions.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Sensors & Workouts")
        .disabled(!model.hasBackup)
    }
}
