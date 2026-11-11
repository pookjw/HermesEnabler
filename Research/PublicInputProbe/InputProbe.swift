import SwiftUI
import HealthKit

@main struct InputProbe: App {
    var body: some Scene { WindowGroup { InputProbeView() } }
}

struct InputProbeView: View {
    @State private var message = "Comprueba qué entradas reales puede leer Salud. No guarda mediciones ni calcula puntuaciones."
    @State private var busy = false
    private let store = HKHealthStore()
    private var quantities: [HKQuantityTypeIdentifier] {
        [.heartRate, .restingHeartRate, .heartRateVariabilitySDNN, .heartRateVariabilityRMSSD, .respiratoryRate, .oxygenSaturation, .appleSleepingWristTemperature, .activeEnergyBurned, .appleExerciseTime, .workoutEffortScore, .estimatedWorkoutEffortScore]
    }
    private var types: [HKSampleType] {
        quantities.compactMap { HKObjectType.quantityType(forIdentifier: $0) } + [HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!, HKObjectType.workoutType(), HKSeriesType.heartbeat()]
    }
    var body: some View {
        ScrollView { VStack(spacing: 12) {
            Text("Entradas de Disposición").font(.headline)
            Text(message).font(.footnote)
            Button("Elegir permisos") { authorize() }.disabled(busy)
            Button("Comprobar disponibilidad") { probe() }.disabled(busy)
        }.padding() }
        .task { if ProcessInfo.processInfo.arguments.contains("--validate-heartbeats") { await validateIntervals() }; if ProcessInfo.processInfo.arguments.contains("--inspect-schemas") { inspectSchemas() } }
    }
    private func inspectSchemas() {
        let report = inspectReadinessSchemas()
        if let data = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]), let root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? data.write(to: root.appendingPathComponent("readiness-schemas.json"), options: .atomic)
        }
        message = "Inspección de tipos completada. Sin lecturas de Salud ni cálculo de puntuaciones."
    }
    private func validateIntervals() async {
        busy = true
        let report = await validateHeartbeatInputs(store: store)
        if let data = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]), let root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? data.write(to: root.appendingPathComponent("heartbeat-calculability.json"), options: .atomic)
        }
        busy = false
        message = "Validación de intervalos completada. No se guardaron valores de latidos ni RMSSD."
    }
    private func authorize() {
        busy = true
        store.requestAuthorization(toShare: [], read: Set(types)) { _, error in
            DispatchQueue.main.async { busy = false; message = error?.localizedDescription ?? "Solicitud terminada. Pulsa Comprobar disponibilidad." }
        }
    }
    private func probe() {
        busy = true
        Task {
            var results: [String: String] = [:]
            let start = Calendar.current.date(byAdding: .day, value: -28, to: Date())!
            for type in types {
                results[type.identifier] = await withCheckedContinuation { continuation in
                    let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: [])
                    let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                        if let error = error as NSError? {
                            continuation.resume(returning: "error \(error.domain) \(error.code)")
                        } else {
                            // Keep availability only. No values, dates or raw samples leave the process.
                            var visible = samples ?? []
                            if type.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue {
                                visible = visible.filter { sample in
                                    guard let category = sample as? HKCategorySample else { return false }
                                    return [1, 3, 4, 5].contains(category.value)
                                }
                            }
                            let days = Set(visible.map { Calendar.current.startOfDay(for: $0.endDate) }).count
                            continuation.resume(returning: visible.isEmpty ? "no visible samples" : "available; coverageDays=\(days)")
                        }
                    }
                    store.execute(query)
                }
            }
            let data = try? JSONSerialization.data(withJSONObject: ["windowDays": 28, "inputs": results] as [String: Any], options: [.prettyPrinted, .sortedKeys])
            if let data, let root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first { try? data.write(to: root.appendingPathComponent("public-input-availability.json"), options: .atomic) }
            await MainActor.run {
                busy = false
                message = "Comprobación completada. Solo se guardó disponibilidad y cobertura por días, sin valores de Salud."
            }
        }
    }
}
