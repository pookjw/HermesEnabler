import Foundation
import HealthKit

// Distinguish calculability from equivalence to Apple's Recovery HRV.
// No RR intervals, timestamps or RMSSD values are persisted or exported.
struct RRAccumulator {
    private var previousBeat: Double?
    private var previousInterval: Double?
    private var squaredDifferenceSum = 0.0
    private(set) var differences = 0
    private(set) var gaps = 0
    private(set) var invalidIntervals = 0
    mutating func append(time: Double, precededByGap: Bool) {
        guard time.isFinite else { previousBeat = nil; previousInterval = nil; invalidIntervals += 1; return }
        if precededByGap { previousBeat = time; previousInterval = nil; gaps += 1; return }
        defer { previousBeat = time }
        guard let beat = previousBeat else { return }
        let interval = time - beat
        guard interval > 0, interval.isFinite else { previousInterval = nil; invalidIntervals += 1; return }
        if let prior = previousInterval {
            let difference = interval - prior
            squaredDifferenceSum += difference * difference
            differences += 1
        }
        previousInterval = interval
    }
    var hasFiniteRMSSD: Bool {
        guard differences > 0 else { return false }
        return sqrt(squaredDifferenceSum / Double(differences)).isFinite
    }
}

func validateHeartbeatInputs(store: HKHealthStore) async -> [String: Any] {
    let start = Calendar.current.date(byAdding: .day, value: -28, to: Date())!
    let (series, fetchError): ([HKHeartbeatSeriesSample], String?) = await withCheckedContinuation { continuation in
        let query = HKSampleQuery(sampleType: HKSeriesType.heartbeat(), predicate: HKQuery.predicateForSamples(withStart: start, end: Date()), limit: 256, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, error in
            let code = (error as NSError?).map { "\($0.domain) \($0.code)" }
            continuation.resume(returning: (samples as? [HKHeartbeatSeriesSample] ?? [], code))
        }
        store.execute(query)
    }
    if let fetchError { return ["status": "query error", "error": fetchError] }
    var calculable = 0, noncalculable = 0, failures = 0, gapSeries = 0
    var days = Set<Date>()
    var errors = Set<String>()
    for sample in series {
        let (accumulator, error): (RRAccumulator, String?) = await withCheckedContinuation { continuation in
            var accumulator = RRAccumulator()
            var finished = false
            let lock = NSLock()
            let query = HKHeartbeatSeriesQuery(heartbeatSeries: sample) { _, time, gap, done, error in
                lock.lock(); defer { lock.unlock() }
                guard !finished else { return }
                if let error = error as NSError? {
                    finished = true
                    continuation.resume(returning: (accumulator, "\(error.domain) \(error.code)"))
                } else {
                    accumulator.append(time: time, precededByGap: gap)
                    if done {
                        finished = true
                        continuation.resume(returning: (accumulator, nil))
                    }
                }
            }
            store.execute(query)
            DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
                lock.lock(); defer { lock.unlock() }
                guard !finished else { return }
                finished = true
                store.stop(query)
                continuation.resume(returning: (accumulator, "timeout"))
            }
        }
        if let error { failures += 1; errors.insert(error); continue }
        if accumulator.gaps > 0 { gapSeries += 1 }
        if accumulator.hasFiniteRMSSD { calculable += 1; days.insert(Calendar.current.startOfDay(for: sample.endDate)) }
        else { noncalculable += 1 }
    }
    return ["status": "completed", "windowDays": 28, "limit": 256, "limitReached": series.count == 256,
            "seriesExamined": series.count, "seriesWithCalculableRMSSD": calculable,
            "seriesWithoutCalculableRMSSD": noncalculable, "seriesWithGaps": gapSeries,
            "queryFailures": failures, "coverageDays": days.count, "errors": errors.sorted(),
            "appleRecoveryHRVEquivalence": "not established", "measurementValuesExported": false]
}
