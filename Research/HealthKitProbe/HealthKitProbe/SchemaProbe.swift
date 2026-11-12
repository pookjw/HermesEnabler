import Foundation
import Darwin

// Records types and keys only. The constructed placeholders never enter a
// health store, score calculation, user-facing result, or persisted data model.
final class SchemaRecorder {
    var fields: [String: String] = [:]
    func record<T>(_ type: T.Type, path: [CodingKey]) {
        fields[path.map(\.stringValue).joined(separator: ".")] = String(reflecting: type)
    }
}
struct SchemaDecoder: Decoder {
    let recorder: SchemaRecorder
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]
    func container<Key: CodingKey>(keyedBy: Key.Type) throws -> KeyedDecodingContainer<Key> { KeyedDecodingContainer(Keys<Key>(decoder: self)) }
    func unkeyedContainer() throws -> any UnkeyedDecodingContainer { EmptyArray(decoder: self) }
    func singleValueContainer() throws -> any SingleValueDecodingContainer { Single(decoder: self) }
    func child(_ key: CodingKey) -> SchemaDecoder { SchemaDecoder(recorder: recorder, codingPath: codingPath + [key]) }
    func value<T: Decodable>(_ type: T.Type) throws -> T {
        recorder.record(type, path: codingPath)
        guard codingPath.count < 12 else { throw Failure.depthLimit }
        if type == String.self { return "" as! T }
        if type == Double.self { return 0.0 as! T }
        if type == Float.self { return Float(0) as! T }
        if type == Bool.self { return false as! T }
        if type == Int.self { return Int(0) as! T }
        if type == Int8.self { return Int8(0) as! T }
        if type == Int16.self { return Int16(0) as! T }
        if type == Int32.self { return Int32(0) as! T }
        if type == Int64.self { return Int64(0) as! T }
        if type == UInt.self { return UInt(0) as! T }
        if type == UInt8.self { return UInt8(0) as! T }
        if type == UInt16.self { return UInt16(0) as! T }
        if type == UInt32.self { return UInt32(0) as! T }
        if type == UInt64.self { return UInt64(0) as! T }
        return try type.init(from: self)
    }
    enum Failure: Error { case depthLimit, emptyArray }
    struct Keys<Key: CodingKey>: KeyedDecodingContainerProtocol {
        let decoder: SchemaDecoder
        var codingPath: [CodingKey] { decoder.codingPath }
        var allKeys: [Key] { [] }
        func contains(_ key: Key) -> Bool { true }
        func decodeNil(forKey key: Key) throws -> Bool { false }
        func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T { try decoder.child(key).value(type) }
        func decodeIfPresent<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T? { decoder.recorder.record(type, path: codingPath + [key]); return nil }
        func nestedContainer<NestedKey: CodingKey>(keyedBy: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> { try decoder.child(key).container(keyedBy: keyedBy) }
        func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer { try decoder.child(key).unkeyedContainer() }
        func superDecoder() throws -> any Decoder { decoder }
        func superDecoder(forKey key: Key) throws -> any Decoder { decoder.child(key) }
    }
    struct EmptyArray: UnkeyedDecodingContainer {
        let decoder: SchemaDecoder
        var codingPath: [CodingKey] { decoder.codingPath }
        var count: Int? { 0 }
        var isAtEnd: Bool { true }
        var currentIndex: Int { 0 }
        mutating func decodeNil() throws -> Bool { true }
        mutating func decode<T: Decodable>(_ type: T.Type) throws -> T { throw Failure.emptyArray }
        mutating func nestedContainer<NestedKey: CodingKey>(keyedBy: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> { throw Failure.emptyArray }
        mutating func nestedUnkeyedContainer() throws -> any UnkeyedDecodingContainer { throw Failure.emptyArray }
        mutating func superDecoder() throws -> any Decoder { throw Failure.emptyArray }
    }
    struct Single: SingleValueDecodingContainer {
        let decoder: SchemaDecoder
        var codingPath: [CodingKey] { decoder.codingPath }
        func decodeNil() -> Bool { false }
        func decode<T: Decodable>(_ type: T.Type) throws -> T { try decoder.value(type) }
    }
}
func inspectReadinessSchemas() -> [[String: Any]] {
    var reports: [[String: Any]] = []
    for framework in ["HealthBalance", "SleepHealth", "AppliedSensingFitness"] {
        let path = "/System/Library/PrivateFrameworks/\(framework).framework/\(framework)"
        guard dlopen(path, RTLD_NOW | RTLD_LOCAL) != nil else { reports.append(["framework": framework, "loaded": false]); continue }
    }
    let names = ["HealthBalance.ReadinessInputsQueryResult", "HealthBalance.ReadinessInputsQueryConfiguration", "HealthBalance.SleepingSampleDaySummary", "HealthBalance.DaytimeVitalsDaySummary", "SleepHealth.SleepScoreDaySummary", "AppliedSensingFitness.ReadinessInputs", "AppliedSensingFitness.RecoveryInputs", "AppliedSensingFitness.OvernightInputs", "AppliedSensingFitness.OvernightMetrics", "AppliedSensingFitness.ReadinessConfiguration", "AppliedSensingFitness.ReadinessParameters", "AppliedSensingFitness.ReadinessComputeResult"]
    for name in names {
        let parts = name.split(separator: ".").map(String.init)
        let mangled = "\(parts[0].utf8.count)\(parts[0])\(parts[1].utf8.count)\(parts[1])V"
        guard let type = _typeByName(mangled) else { reports.append(["type": name, "available": false]); continue }
        guard let decodable = type as? any Decodable.Type else { reports.append(["type": name, "available": true, "decodable": false]); continue }
        let recorder = SchemaRecorder()
        var status = "decoded placeholders; discarded"
        do { _ = try decodable.init(from: SchemaDecoder(recorder: recorder)) }
        catch { status = "stopped: \(String(reflecting: Swift.type(of: error)))" }
        reports.append(["type": name, "available": true, "fields": recorder.fields, "status": status])
    }
    return reports
}
