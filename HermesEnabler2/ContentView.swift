import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
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
    @State private var appleIntelligenceEnabled = false
    @State private var onDeviceSiriEnabled = false
    @State private var audioIntelligenceEnabled = false
    @State private var regionCodeSelection = ""
    @State private var salesRegionSelection = ""
    @State private var screenWidth = 0
    @State private var screenHeight = 0
    @State private var resolutionOverridden = false
    @State private var backups: [BackupItem] = []
    @State private var selectedBackupID = ""
    @State private var showRestoreConfirmation = false

    private struct BackupItem: Identifiable {
        let id: String
        let date: Date
        let kind: String
    }

    private struct ResolutionPreset: Identifiable {
        let title: String
        let width: Int
        let height: Int
        var id: String { "\(width)x\(height)" }
    }

    private static let resolutionPresets = [
        ResolutionPreset(title: "SE · 40 mm", width: 324, height: 394),
        ResolutionPreset(title: "SE · 44 mm", width: 368, height: 448),
        ResolutionPreset(title: "S7–S9 · 41 mm", width: 352, height: 430),
        ResolutionPreset(title: "S7–S9 · 45 mm", width: 396, height: 484),
        ResolutionPreset(title: "S10–S12 · 42 mm", width: 374, height: 446),
        ResolutionPreset(title: "S10–S12 · 46 mm", width: 416, height: 496)
    ]

    private struct RegionOption: Identifiable {
        let title: String
        let regionCode: String
        let salesSuffix: String
        var id: String { regionCode }
    }

    // Region code and sales region are deliberately independent. The former
    // writes RegionCode only; the latter writes only the sales suffix field.
    private static let regionOptions = [
        RegionOption(title: "United States", regionCode: "LL", salesSuffix: "LL/A"),
        RegionOption(title: "Hong Kong", regionCode: "ZA", salesSuffix: "ZA/A"),
        RegionOption(title: "Japan", regionCode: "J", salesSuffix: "J/A"),
        RegionOption(title: "China (Mainland)", regionCode: "CH", salesSuffix: "CH/A"),
        RegionOption(title: "Taiwan", regionCode: "TA", salesSuffix: "TA/A"),
        RegionOption(title: "United Kingdom", regionCode: "B", salesSuffix: "B/A"),
        RegionOption(title: "Canada", regionCode: "C", salesSuffix: "C/A")
    ]

    var body: some View {
        NavigationStack {
            if !hasBackup {
                backupView
            } else {
            List {
                Section("Features") {
                    NavigationLink { watchFacesView } label: {
                        Label("Watch Faces", systemImage: "clock")
                    }
                    NavigationLink { displayAndControlsView } label: {
                        Label("Display & Controls", systemImage: "switch.2")
                    }
                    NavigationLink { sensorsAndWorkoutsView } label: {
                        Label("Sensors & Workouts", systemImage: "heart")
                    }
                    NavigationLink { intelligenceView } label: {
                        Label("Siri & Intelligence", systemImage: "sparkles")
                    }
                }
                Section("Utilities") {
                    NavigationLink { backupView } label: {
                        Label("MG Backups", systemImage: "archivebox")
                    }
                    Button("Restart Carousel") {
                        message = "Starting respring. View the app log if nothing happens."
                        BQRespring()
                    }
                }
                Section("Status") {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("HermesEnabler")
            }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active {
                refreshBackups()
                if hasBackup { refreshCapabilityStates() }
            }
        }
        .confirmationDialog("Restore this backup?", isPresented: $showRestoreConfirmation) {
            Button("Restore MG", role: .destructive) { perform(.restoreBackup(selectedBackupID)) }
        } message: {
            Text("The current MG will be backed up automatically first. Restart the watch after restoring.")
        }
        .alert("MobileGestalt Access Failed", isPresented: $showAccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("An App Group ID may be missing, or this watchOS version may be incompatible. Check the app's App Group configuration and watchOS version.")
        }
    }

    private var backupView: some View {
        List {
            if !hasBackup {
                Section("First Launch") {
                    Text("An initial MobileGestalt backup is required before using any feature. It will be kept as the original and cannot be overwritten here.")
                        .font(.footnote)
                    Button("Create Initial Backup") { perform(.backup) }
                }
            } else {
                Section("Create Backup") {
                    Button("Back Up Current MG") { perform(.manualBackup) }
                    Text("Every MG write and restore also creates an automatic backup first.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Backup Library") {
                    ForEach(backups) { backup in
                        Button {
                            selectedBackupID = backup.id
                            showRestoreConfirmation = true
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(backup.kind + " Backup")
                                Text(backup.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            Section("Status") { Text(message).font(.footnote).foregroundStyle(.secondary) }
        }
        .navigationTitle("MG Backups")
        .onAppear(perform: refreshBackups)
    }

    private func refreshBackups() {
        hasBackup = BQBackupExists()
        backups = BQListGestaltBackups().compactMap { record in
            guard let id = record["id"] as? String, let date = record["date"] as? Date else { return nil }
            return BackupItem(id: id, date: date, kind: (record["kind"] as? String) ?? "Initial")
        }
    }

    private var watchFacesView: some View {
        List {
            Section {
                Toggle("Hermès", isOn: Binding(get: { hermesEnabled }, set: { perform(.hermes($0)) }))
                Toggle("Ultra Faces", isOn: Binding(get: { ultraFacesEnabled }, set: { perform(.ultraFaces($0)) }))
            } footer: {
                Text("Restart Carousel after changing a face capability.")
            }
        }
        .navigationTitle("Watch Faces")
        .disabled(!hasBackup)
    }

    private var displayAndControlsView: some View {
        List {
            Section("Display") {
                Toggle("Always-On Display", isOn: Binding(get: { aodEnabled }, set: { perform(.aod($0)) }))
                Toggle("AOD 1 Hz", isOn: Binding(get: { aodSecondsEnabled }, set: { perform(.aodSeconds($0)) }))
                Toggle("AOD Vibrancy", isOn: Binding(get: { aodVibrancyEnabled }, set: { perform(.aodVibrancy($0)) }))
                Toggle("Periodic Ambient Light Updates", isOn: Binding(get: { periodicALSUpdatesEnabled }, set: { perform(.periodicALSUpdates($0)) }))
                NavigationLink { resolutionOptionsView } label: {
                    optionRow("Screen Resolution", value: screenWidth > 0 ? "\(screenWidth) × \(screenHeight) px" : "Unavailable")
                }
            }
            Section("Controls") {
                Toggle("Action Button", isOn: Binding(get: { actionButtonEnabled }, set: { perform(.actionButton($0)) }))
                Toggle("Double Tap", isOn: Binding(get: { doubleTapEnabled }, set: { perform(.doubleTap($0)) }))
                Toggle("On-Screen Keyboard", isOn: Binding(get: { watchKeyboardEnabled }, set: { perform(.watchKeyboard($0)) }))
                Toggle("Raise Wrist to Wake", isOn: Binding(get: { rotateToWakeEnabled }, set: { perform(.rotateToWake($0)) }))
            }
            Section("Voice") {
                Toggle("Raise to Speak", isOn: Binding(get: { raiseToSpeakEnabled }, set: { perform(.raiseToSpeak($0)) }))
                Toggle("Siri Listening Capability", isOn: Binding(get: { alwaysListeningEnabled }, set: { perform(.alwaysListening($0)) }))
            }
            Text("Some options require matching display, sensor, or audio hardware.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Display & Controls")
        .disabled(!hasBackup)
    }

    private var sensorsAndWorkoutsView: some View {
        List {
            Section("Sensors") {
                Toggle("Depth Sensor", isOn: Binding(get: { depthEnabled }, set: { perform(.depth($0)) }))
                Toggle("Absolute Altimeter", isOn: Binding(get: { absoluteAltimeterEnabled }, set: { perform(.absoluteAltimeter($0)) }))
                Toggle("Always-On Compass", isOn: Binding(get: { alwaysOnCompassEnabled }, set: { perform(.alwaysOnCompass($0)) }))
                Toggle("Compass Orienteering", isOn: Binding(get: { compassOrienteeringEnabled }, set: { perform(.compassOrienteering($0)) }))
            }
            Section("Health & Workouts") {
                Toggle("Continuous Heart Rate", isOn: Binding(get: { continuousHeartRateEnabled }, set: { perform(.continuousHeartRate($0)) }))
                Toggle("Noise Exposure", isOn: Binding(get: { environmentalDosimetryEnabled }, set: { perform(.environmentalDosimetry($0)) }))
                Toggle("Battery Information", isOn: Binding(get: { batteryInformationEnabled }, set: { perform(.batteryInformation($0)) }))
                Toggle("Swimming Workouts", isOn: Binding(get: { swimmingWorkoutsEnabled }, set: { perform(.swimmingWorkouts($0)) }))
            }
            Text("Capability flags do not add missing sensors or override Health permissions.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Sensors & Workouts")
        .disabled(!hasBackup)
    }

    private var intelligenceView: some View {
        List {
            Section("Region") {
                NavigationLink { regionCodeOptionsView } label: {
                    optionRow("Region Code", value: selectedRegionCodeTitle)
                }
                NavigationLink { salesRegionOptionsView } label: {
                    optionRow("Sales Region", value: selectedSalesRegionTitle)
                }
            }
            Section("Watch Capabilities") {
                Toggle("Apple Intelligence / Siri AI", isOn: Binding(get: { appleIntelligenceEnabled }, set: { perform(.appleIntelligence($0)) }))
                Toggle("On-Device Siri", isOn: Binding(get: { onDeviceSiriEnabled }, set: { perform(.onDeviceSiri($0)) }))
                Toggle("Audio Intelligence", isOn: Binding(get: { audioIntelligenceEnabled }, set: { perform(.audioIntelligence($0)) }))
            }
            Text("Siri AI needs watchOS 27, a supported watch and a paired Apple Intelligence iPhone. Audio Intelligence is for Series 12 / Ultra 4 hardware. These flags cannot add missing hardware or bypass service eligibility.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Siri & Intelligence")
        .disabled(!hasBackup)
    }

    private var resolutionOptionsView: some View {
        List {
            Section("Current Reported Size") {
                Text(screenWidth > 0 ? "\(screenWidth) × \(screenHeight) pixels" : "Could not read dimensions")
                if resolutionOverridden {
                    Button("Restore Original Size") { perform(.resolution(0, 0)) }
                }
            }
            Section("Presets") {
                ForEach(Self.resolutionPresets) { preset in
                    Button { perform(.resolution(preset.width, preset.height)) } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            selectionRow(preset.title, selected: screenWidth == preset.width && screenHeight == preset.height)
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
        .disabled(!hasBackup)
    }

    private var regionCodeOptionsView: some View {
        List {
            Text("Changes RegionCode only. It leaves the sales-region suffix unchanged.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Section("Choose Region Code") {
                ForEach(Self.regionOptions) { option in
                    Button { perform(.regionCode(option.regionCode)) } label: {
                        selectionRow(option.title, selected: regionCodeSelection == option.regionCode)
                    }
                }
            }
        }
        .navigationTitle("Region Code")
        .disabled(!hasBackup)
    }

    private var salesRegionOptionsView: some View {
        List {
            Text("Changes the sales-region suffix only. It may cause factory-information tools to report a mismatch.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Section("Choose Sales Region") {
                ForEach(Self.regionOptions) { option in
                    Button { perform(.salesRegion(option.salesSuffix)) } label: {
                        selectionRow(option.title, selected: salesRegionSelection == option.salesSuffix)
                    }
                }
            }
        }
        .navigationTitle("Sales Region")
        .disabled(!hasBackup)
    }

    private var selectedRegionCodeTitle: String {
        Self.regionOptions.first(where: { $0.regionCode == regionCodeSelection })?.title ?? "Other / unchanged"
    }

    private var selectedSalesRegionTitle: String {
        Self.regionOptions.first(where: { $0.salesSuffix == salesRegionSelection })?.title ?? "Other / unchanged"
    }

    private func optionRow(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            Text(value).font(.footnote).foregroundStyle(.secondary)
        }
    }

    private func selectionRow(_ title: String, selected: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            if selected { Image(systemName: "checkmark") }
        }
    }

    private enum Action {
        case backup, manualBackup, restoreBackup(String)
        case hermes(Bool)
        case ultraFaces(Bool)
        case aod(Bool), aodSeconds(Bool), actionButton(Bool), doubleTap(Bool)
        case depth(Bool), absoluteAltimeter(Bool), alwaysOnCompass(Bool), aodVibrancy(Bool)
        case watchKeyboard(Bool), periodicALSUpdates(Bool), raiseToSpeak(Bool), continuousHeartRate(Bool)
        case compassOrienteering(Bool), environmentalDosimetry(Bool), batteryInformation(Bool)
        case alwaysListening(Bool), rotateToWake(Bool), swimmingWorkouts(Bool)
        case regionCode(String), salesRegion(String)
        case appleIntelligence(Bool), onDeviceSiri(Bool), audioIntelligence(Bool)
        case resolution(Int, Int)
    }

    private func perform(_ action: Action) {
        var error: NSString?
        let result: String
        if !BQCoreInit() {
            result = "MobileGestalt access is unavailable on this device."
        } else {
            switch action {
            case .backup:
                result = BQCreateGestaltBackup(true, &error) != nil
                    ? "Initial MobileGestalt backup saved."
                    : ((error as String?) ?? "Initial backup failed.")
            case .manualBackup:
                result = BQCreateGestaltBackup(false, &error) != nil
                    ? "Manual MobileGestalt backup saved."
                    : ((error as String?) ?? "Manual backup failed.")
            case .restoreBackup(let identifier):
                result = BQRestoreGestaltBackup(identifier, &error)
                    ? "Selected backup restored. Restart the watch."
                    : ((error as String?) ?? "Restore failed.")
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
            case .regionCode(let code):
                guard !code.isEmpty else {
                    refreshCapabilityStates()
                    return
                }
                let title = Self.regionOptions.first(where: { $0.regionCode == code })?.title ?? code
                result = BQSetRegionCode(code, &error)
                    ? "Region Code set to \(title). Restart the watch to reload it."
                    : ((error as String?) ?? "Could not update Region Code.")
            case .salesRegion(let suffix):
                guard !suffix.isEmpty else {
                    refreshCapabilityStates()
                    return
                }
                let title = Self.regionOptions.first(where: { $0.salesSuffix == suffix })?.title ?? suffix
                result = BQSetSalesRegion(suffix, &error)
                    ? "Sales Region set to \(title). Restart the watch to reload it."
                    : ((error as String?) ?? "Could not update Sales Region.")
            case .appleIntelligence(let enabled):
                result = BQSetAppleIntelligence(enabled, &error)
                    ? "Apple Intelligence capability turned \(enabled ? "on" : "off"). Restart the watch to reload it."
                    : ((error as String?) ?? "Could not update Apple Intelligence capability.")
            case .onDeviceSiri(let enabled):
                result = BQSetOnDeviceSiri(enabled, &error)
                    ? "On-Device Siri capability turned \(enabled ? "on" : "off"). Restart the watch to reload it."
                    : ((error as String?) ?? "Could not update On-Device Siri capability.")
            case .audioIntelligence(let enabled):
                result = BQSetAudioIntelligence(enabled, &error)
                    ? "Audio Intelligence capability turned \(enabled ? "on" : "off"). Restart the watch to reload it."
                    : ((error as String?) ?? "Could not update Audio Intelligence capability.")
            case .resolution(let width, let height):
                result = BQSetScreenResolution(width, height, &error)
                    ? (width == 0 ? "Original screen dimensions restored. Restart the watch." : "Reported screen size set to \(width) × \(height). Restart the watch.")
                    : ((error as String?) ?? "Could not update screen dimensions.")
            }
        }
        refreshBackups()
        message = result
        if (error as String?) == BQNoSandboxTokenError {
            showAccessAlert = true
        }
        if hasBackup { refreshCapabilityStates() }
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
        value = ObjCBool(false)
        appleIntelligenceEnabled = BQGetAppleIntelligence(&value, &error) && value.boolValue
        value = ObjCBool(false)
        onDeviceSiriEnabled = BQGetOnDeviceSiri(&value, &error) && value.boolValue
        value = ObjCBool(false)
        audioIntelligenceEnabled = BQGetAudioIntelligence(&value, &error) && value.boolValue
        if let code = BQGetRegionCode(&error) as String?,
           Self.regionOptions.contains(where: { $0.regionCode == code }) {
            regionCodeSelection = code
        } else {
            regionCodeSelection = ""
        }
        error = nil
        if let suffix = BQGetSalesRegion(&error) as String?,
           Self.regionOptions.contains(where: { $0.salesSuffix == suffix }) {
            salesRegionSelection = suffix
        } else {
            salesRegionSelection = ""
        }
        hasBackup = BQBackupExists()
        error = nil
        var width = 0
        var height = 0
        var overridden = ObjCBool(false)
        if BQGetScreenResolution(&width, &height, &overridden, &error) {
            screenWidth = width
            screenHeight = height
            resolutionOverridden = overridden.boolValue
        } else {
            screenWidth = 0
            screenHeight = 0
            resolutionOverridden = false
        }
    }
}
