import SwiftUI
import Observation

@Observable
final class ContentModel {
    var message = BQBackupExists() ? "Backup ready." : "Back up MobileGestalt before making changes."
    var hasBackup = BQBackupExists()
    var showAccessAlert = false
    var aodEnabled = false
    var aodSecondsEnabled = false
    var actionButtonEnabled = false
    var doubleTapEnabled = false
    var depthEnabled = false
    var absoluteAltimeterEnabled = false
    var alwaysOnCompassEnabled = false
    var aodVibrancyEnabled = false
    var hermesEnabled = false
    var ultraFacesEnabled = false
    var watchKeyboardEnabled = false
    var periodicALSUpdatesEnabled = false
    var raiseToSpeakEnabled = false
    var continuousHeartRateEnabled = false
    var compassOrienteeringEnabled = false
    var environmentalDosimetryEnabled = false
    var batteryInformationEnabled = false
    var alwaysListeningEnabled = false
    var rotateToWakeEnabled = false
    var swimmingWorkoutsEnabled = false
    var appleIntelligenceEnabled = false
    var onDeviceSiriEnabled = false
    var audioIntelligenceEnabled = false
    var regionCodeSelection = ""
    var salesRegionSelection = ""
    var screenWidth = 0
    var screenHeight = 0
    var resolutionOverridden = false
    var backups: [BackupItem] = []
    var selectedBackupID = ""
    var showRestoreConfirmation = false

    struct BackupItem: Identifiable {
        let id: String
        let date: Date
        let kind: String
    }

    struct ResolutionPreset: Identifiable {
        let title: String
        let width: Int
        let height: Int
        var id: String { "\(width)x\(height)" }
    }

    static let resolutionPresets = [
        ResolutionPreset(title: "SE · 40 mm", width: 324, height: 394),
        ResolutionPreset(title: "SE · 44 mm", width: 368, height: 448),
        ResolutionPreset(title: "S7–S9 · 41 mm", width: 352, height: 430),
        ResolutionPreset(title: "S7–S9 · 45 mm", width: 396, height: 484),
        ResolutionPreset(title: "S10–S12 · 42 mm", width: 374, height: 446),
        ResolutionPreset(title: "S10–S12 · 46 mm", width: 416, height: 496)
    ]

    struct RegionOption: Identifiable {
        let title: String
        let regionCode: String
        let salesSuffix: String
        var id: String { regionCode }
    }

    // Region code and sales region are deliberately independent. The former
    // writes RegionCode only; the latter writes only the sales suffix field.
    static let regionOptions = [
        RegionOption(title: "United States", regionCode: "LL", salesSuffix: "LL/A"),
        RegionOption(title: "Hong Kong", regionCode: "ZA", salesSuffix: "ZA/A"),
        RegionOption(title: "Japan", regionCode: "J", salesSuffix: "J/A"),
        RegionOption(title: "China (Mainland)", regionCode: "CH", salesSuffix: "CH/A"),
        RegionOption(title: "Taiwan", regionCode: "TA", salesSuffix: "TA/A"),
        RegionOption(title: "United Kingdom", regionCode: "B", salesSuffix: "B/A"),
        RegionOption(title: "Canada", regionCode: "C", salesSuffix: "C/A")
    ]

    func refreshBackups() {
        hasBackup = BQBackupExists()
        backups = BQListGestaltBackups().compactMap { record in
            guard let id = record["id"] as? String, let date = record["date"] as? Date else { return nil }
            return BackupItem(id: id, date: date, kind: (record["kind"] as? String) ?? "Initial")
        }
    }

    var selectedRegionCodeTitle: String {
        Self.regionOptions.first(where: { $0.regionCode == regionCodeSelection })?.title ?? "Other / unchanged"
    }

    var selectedSalesRegionTitle: String {
        Self.regionOptions.first(where: { $0.salesSuffix == salesRegionSelection })?.title ?? "Other / unchanged"
    }

    enum Action {
        case backup, manualBackup, restoreBackup(String)
        case dumpMobileGestalt
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

    func perform(_ action: Action) {
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
            case .dumpMobileGestalt:
                result = BQDumpMobileGestalt(&error)
                    ? "MobileGestalt dumped to the app log (bqtool.log). Share it to report a build."
                    : ((error as String?) ?? "Could not read MobileGestalt.")
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

    func refreshCapabilityStates() {
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
