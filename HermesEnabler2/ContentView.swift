import SwiftUI

struct ContentView: View {
    @State private var message = BQBackupExists() ? "Backup ready." : "Back up MobileGestalt before making changes."
    @State private var hasBackup = BQBackupExists()
    @State private var showAccessAlert = false
    @State private var aodEnabled = false
    @State private var aodSecondsEnabled = false
    @State private var actionButtonEnabled = false
    @State private var doubleTapEnabled = false
    @State private var depthEnabled = false
    @State private var absoluteAltimeterEnabled = false
    @State private var alwaysOnCompassEnabled = false
    @State private var aodVibrancyEnabled = false
    @State private var hermesEnabled = false
    @State private var ultraFacesEnabled = false
    @State private var watchKeyboardEnabled = false
    @State private var periodicALSUpdatesEnabled = false
    @State private var raiseToSpeakEnabled = false
    @State private var continuousHeartRateEnabled = false
    @State private var compassOrienteeringEnabled = false
    @State private var environmentalDosimetryEnabled = false
    @State private var batteryInformationEnabled = false
    @State private var alwaysListeningEnabled = false
    @State private var rotateToWakeEnabled = false
    @State private var swimmingWorkoutsEnabled = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if !hasBackup {
                    Button("Backup MG") { perform(.backup) }
                }
                Toggle("Hermès", isOn: Binding(
                    get: { hermesEnabled },
                    set: { perform(.hermes($0)) }
                ))
                    .disabled(!hasBackup)
                Toggle("Ultra Faces", isOn: Binding(
                    get: { ultraFacesEnabled },
                    set: { perform(.ultraFaces($0)) }
                ))
                    .disabled(!hasBackup)
                Toggle("AOD", isOn: Binding(
                    get: { aodEnabled },
                    set: { perform(.aod($0)) }
                ))
                    .disabled(!hasBackup)
                Toggle("AOD 1Hz", isOn: Binding(
                    get: { aodSecondsEnabled },
                    set: { perform(.aodSeconds($0)) }
                ))
                    .disabled(!hasBackup)
                Toggle("Action Button", isOn: Binding(
                    get: { actionButtonEnabled },
                    set: { perform(.actionButton($0)) }
                ))
                    .disabled(!hasBackup)
                Toggle("Double Tap", isOn: Binding(
                    get: { doubleTapEnabled },
                    set: { perform(.doubleTap($0)) }
                ))
                    .disabled(!hasBackup)
                Toggle("Depth Sensor", isOn: Binding(
                    get: { depthEnabled },
                    set: { perform(.depth($0)) }
                ))
                    .disabled(!hasBackup)
                Toggle("Absolute Altimeter", isOn: Binding(
                    get: { absoluteAltimeterEnabled },
                    set: { perform(.absoluteAltimeter($0)) }
                ))
                    .disabled(!hasBackup)
                Toggle("Always-On Compass", isOn: Binding(
                    get: { alwaysOnCompassEnabled },
                    set: { perform(.alwaysOnCompass($0)) }
                ))
                    .disabled(!hasBackup)
                Toggle("AOD Vibrancy", isOn: Binding(
                    get: { aodVibrancyEnabled },
                    set: { perform(.aodVibrancy($0)) }
                ))
                    .disabled(!hasBackup)
                Toggle("On-Screen Keyboard", isOn: Binding(
                    get: { watchKeyboardEnabled },
                    set: { perform(.watchKeyboard($0)) }
                ))
                    .disabled(!hasBackup)
                Toggle("Periodic Ambient Light Updates", isOn: Binding(
                    get: { periodicALSUpdatesEnabled },
                    set: { perform(.periodicALSUpdates($0)) }
                ))
                    .disabled(!hasBackup)
                Toggle("Raise to Speak", isOn: Binding(
                    get: { raiseToSpeakEnabled },
                    set: { perform(.raiseToSpeak($0)) }
                ))
                    .disabled(!hasBackup)
                Toggle("Continuous Heart Rate", isOn: Binding(
                    get: { continuousHeartRateEnabled },
                    set: { perform(.continuousHeartRate($0)) }
                ))
                    .disabled(!hasBackup)
                Toggle("Compass Orienteering", isOn: Binding(
                    get: { compassOrienteeringEnabled },
                    set: { perform(.compassOrienteering($0)) }
                ))
                    .disabled(!hasBackup)
                Toggle("Noise Exposure", isOn: Binding(
                    get: { environmentalDosimetryEnabled },
                    set: { perform(.environmentalDosimetry($0)) }
                ))
                    .disabled(!hasBackup)
                Toggle("Battery Information", isOn: Binding(
                    get: { batteryInformationEnabled },
                    set: { perform(.batteryInformation($0)) }
                ))
                    .disabled(!hasBackup)
                Toggle("Always Listening", isOn: Binding(
                    get: { alwaysListeningEnabled },
                    set: { perform(.alwaysListening($0)) }
                ))
                    .disabled(!hasBackup)
                Toggle("Raise Wrist to Wake", isOn: Binding(
                    get: { rotateToWakeEnabled },
                    set: { perform(.rotateToWake($0)) }
                ))
                    .disabled(!hasBackup)
                Toggle("Swimming Workouts", isOn: Binding(
                    get: { swimmingWorkoutsEnabled },
                    set: { perform(.swimmingWorkouts($0)) }
                ))
                    .disabled(!hasBackup)
                Text("Some capabilities require matching sensors and hardware.")
                    .font(.caption2).foregroundStyle(.secondary)
                Button("Restart Carousel") {
                    message = "Starting respring. View the app log if nothing happens."
                    BQRespring()
                }
                Button("Restore MG") { perform(.restore) }
                    .disabled(!hasBackup)
                Button("Dump MG") { perform(.dump) }
                Text(message).font(.footnote).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear(perform: refreshCapabilityStates)
        .alert("MobileGestalt Access Failed", isPresented: $showAccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("An App Group ID may be missing, or this watchOS version may be incompatible. Check the app's App Group configuration and watchOS version.")
        }
    }

    private enum Action {
        case backup, restore, dump
        case hermes(Bool)
        case ultraFaces(Bool)
        case aod(Bool), aodSeconds(Bool), actionButton(Bool), doubleTap(Bool)
        case depth(Bool), absoluteAltimeter(Bool), alwaysOnCompass(Bool), aodVibrancy(Bool)
        case watchKeyboard(Bool), periodicALSUpdates(Bool), raiseToSpeak(Bool), continuousHeartRate(Bool)
        case compassOrienteering(Bool), environmentalDosimetry(Bool), batteryInformation(Bool)
        case alwaysListening(Bool), rotateToWake(Bool), swimmingWorkouts(Bool)
    }

    private func perform(_ action: Action) {
        var error: NSString?
        let result: String
        if !BQCoreInit() {
            result = "MobileGestalt access is unavailable on this device."
        } else {
            switch action {
            case .backup:
                if BQBackupExists() {
                    result = "A backup already exists and was preserved."
                } else if BQLoadGestalt(&error) != nil && BQBackupExists() {
                    result = "MobileGestalt backup saved."
                } else {
                    result = (error as String?) ?? "Backup could not be verified."
                }
            case .hermes(let enabled):
                result = BQSetHermesEnabled(enabled, &error)
                    ? "Hermès turned \(enabled ? "on" : "off"). Restart Carousel to reload it."
                    : ((error as String?) ?? "Could not update DeviceBrand.")
            case .ultraFaces(let enabled):
                result = BQSetUltraFacesEnabled(enabled, &error)
                    ? "Ultra Faces turned \(enabled ? "on" : "off"). Restart the watch to reload it."
                    : ((error as String?) ?? "Could not update Ultra Faces.")
            case .aod(let enabled):
                result = BQSetAODSupport(enabled, &error)
                    ? "AOD turned \(enabled ? "on" : "off"). Restart Carousel to reload it."
                    : ((error as String?) ?? "Could not update AOD capabilities.")
            case .aodSeconds(let enabled):
                result = BQSetAODSecondsSupport(enabled, &error)
                    ? "AOD 1Hz turned \(enabled ? "on" : "off"). Restart Carousel to reload it. Faces must support seconds in AOD."
                    : ((error as String?) ?? "Could not update AOD flipbook capability.")
            case .actionButton(let enabled):
                result = BQSetActionButton(enabled, &error)
                    ? "Action Button turned \(enabled ? "on" : "off"). Restart Carousel to reload it."
                    : ((error as String?) ?? "Could not update Action Button capability.")
            case .doubleTap(let enabled):
                result = BQSetDoubleTap(enabled, &error)
                    ? "Double Tap turned \(enabled ? "on" : "off"). Restart Carousel to reload it."
                    : ((error as String?) ?? "Could not update Double Tap capability.")
            case .depth(let enabled):
                result = BQSetDepthCapability(enabled, &error)
                    ? "Depth Sensor capability turned \(enabled ? "on" : "off"). Restart Carousel to reload it. Sensor hardware is still required."
                    : ((error as String?) ?? "Could not update Depth Sensor capability.")
            case .absoluteAltimeter(let enabled):
                result = BQSetAbsoluteAltimeter(enabled, &error)
                    ? "Absolute Altimeter capability turned \(enabled ? "on" : "off"). Restart Carousel to reload it."
                    : ((error as String?) ?? "Could not update Absolute Altimeter capability.")
            case .alwaysOnCompass(let enabled):
                result = BQSetAlwaysOnCompass(enabled, &error)
                    ? "Always-On Compass capability turned \(enabled ? "on" : "off"). Restart Carousel to reload it."
                    : ((error as String?) ?? "Could not update Always-On Compass capability.")
            case .aodVibrancy(let enabled):
                result = BQSetAODVibrancy(enabled, &error)
                    ? "AOD Vibrancy capability turned \(enabled ? "on" : "off"). Restart Carousel to reload it."
                    : ((error as String?) ?? "Could not update AOD Vibrancy capability.")
            case .watchKeyboard(let enabled):
                result = BQSetWatchKeyboard(enabled, &error)
                    ? "On-Screen Keyboard capability turned \(enabled ? "on" : "off"). Restart Carousel to reload it."
                    : ((error as String?) ?? "Could not update keyboard capability.")
            case .periodicALSUpdates(let enabled):
                result = BQSetPeriodicALSUpdates(enabled, &error)
                    ? "Periodic ambient light updates turned \(enabled ? "on" : "off"). Restart Carousel to reload it."
                    : ((error as String?) ?? "Could not update ambient light capability.")
            case .raiseToSpeak(let enabled):
                result = BQSetRaiseToSpeak(enabled, &error)
                    ? "Raise to Speak turned \(enabled ? "on" : "off"). Restart Carousel to reload it."
                    : ((error as String?) ?? "Could not update Raise to Speak capability.")
            case .continuousHeartRate(let enabled):
                result = BQSetContinuousHeartRate(enabled, &error)
                    ? "Continuous Heart Rate turned \(enabled ? "on" : "off"). Restart Carousel to reload it. Sensor hardware and Health settings still apply."
                    : ((error as String?) ?? "Could not update continuous heart rate capability.")
            case .compassOrienteering(let enabled):
                result = BQSetCompassOrienteering(enabled, &error)
                    ? "Compass Orienteering turned \(enabled ? "on" : "off"). Restart Carousel to reload it."
                    : ((error as String?) ?? "Could not update compass capability.")
            case .environmentalDosimetry(let enabled):
                result = BQSetEnvironmentalDosimetry(enabled, &error)
                    ? "Noise Exposure capability turned \(enabled ? "on" : "off"). Restart Carousel to reload it."
                    : ((error as String?) ?? "Could not update noise exposure capability.")
            case .batteryInformation(let enabled):
                result = BQSetBatteryInformation(enabled, &error)
                    ? "Battery Information capability turned \(enabled ? "on" : "off"). Restart Carousel to reload it."
                    : ((error as String?) ?? "Could not update battery information capability.")
            case .alwaysListening(let enabled):
                result = BQSetAlwaysListening(enabled, &error)
                    ? "Always Listening capability turned \(enabled ? "on" : "off"). Restart Carousel to reload it. Siri settings and supported audio hardware still apply."
                    : ((error as String?) ?? "Could not update Always Listening capability.")
            case .rotateToWake(let enabled):
                result = BQSetRotateToWake(enabled, &error)
                    ? "Raise Wrist to Wake capability turned \(enabled ? "on" : "off"). Restart Carousel to reload it."
                    : ((error as String?) ?? "Could not update Raise Wrist to Wake capability.")
            case .swimmingWorkouts(let enabled):
                result = BQSetSwimmingWorkouts(enabled, &error)
                    ? "Swimming Workouts capability turned \(enabled ? "on" : "off"). Restart Carousel to reload it."
                    : ((error as String?) ?? "Could not update Swimming Workouts capability.")
            case .dump:
                result = BQDumpMobileGestalt(&error)
                    ? "MG dumped to Documents/bqtool.log. Send that log."
                    : ((error as String?) ?? "Could not read MobileGestalt.")
            case .restore:
                result = BQRestoreGestalt(&error) ? "MobileGestalt restored. Restart the watch to reload it." : ((error as String?) ?? "Restore failed.")
            }
        }
        hasBackup = BQBackupExists()
        message = result
        if (error as String?) == BQNoSandboxTokenError {
            showAccessAlert = true
        }
        refreshCapabilityStates()
    }

    private func refreshCapabilityStates() {
        var error: NSString?
        var value = ObjCBool(false)
        hermesEnabled = BQGetHermesEnabled(&value, &error) && value.boolValue
        value = ObjCBool(false)
        ultraFacesEnabled = BQGetUltraFacesEnabled(&value, &error) && value.boolValue
        value = ObjCBool(false)
        aodEnabled = BQGetAODSupport(&value, &error) && value.boolValue
        value = ObjCBool(false)
        aodSecondsEnabled = BQGetAODSecondsSupport(&value, &error) && value.boolValue
        value = ObjCBool(false)
        actionButtonEnabled = BQGetActionButton(&value, &error) && value.boolValue
        value = ObjCBool(false)
        doubleTapEnabled = BQGetDoubleTap(&value, &error) && value.boolValue
        value = ObjCBool(false)
        depthEnabled = BQGetDepthCapability(&value, &error) && value.boolValue
        value = ObjCBool(false)
        absoluteAltimeterEnabled = BQGetAbsoluteAltimeter(&value, &error) && value.boolValue
        value = ObjCBool(false)
        alwaysOnCompassEnabled = BQGetAlwaysOnCompass(&value, &error) && value.boolValue
        value = ObjCBool(false)
        aodVibrancyEnabled = BQGetAODVibrancy(&value, &error) && value.boolValue
        value = ObjCBool(false)
        watchKeyboardEnabled = BQGetWatchKeyboard(&value, &error) && value.boolValue
        value = ObjCBool(false)
        periodicALSUpdatesEnabled = BQGetPeriodicALSUpdates(&value, &error) && value.boolValue
        value = ObjCBool(false)
        raiseToSpeakEnabled = BQGetRaiseToSpeak(&value, &error) && value.boolValue
        value = ObjCBool(false)
        continuousHeartRateEnabled = BQGetContinuousHeartRate(&value, &error) && value.boolValue
        value = ObjCBool(false)
        compassOrienteeringEnabled = BQGetCompassOrienteering(&value, &error) && value.boolValue
        value = ObjCBool(false)
        environmentalDosimetryEnabled = BQGetEnvironmentalDosimetry(&value, &error) && value.boolValue
        value = ObjCBool(false)
        batteryInformationEnabled = BQGetBatteryInformation(&value, &error) && value.boolValue
        value = ObjCBool(false)
        alwaysListeningEnabled = BQGetAlwaysListening(&value, &error) && value.boolValue
        value = ObjCBool(false)
        rotateToWakeEnabled = BQGetRotateToWake(&value, &error) && value.boolValue
        value = ObjCBool(false)
        swimmingWorkoutsEnabled = BQGetSwimmingWorkouts(&value, &error) && value.boolValue
    }
}
