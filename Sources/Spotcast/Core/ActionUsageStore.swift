import Foundation

struct ActionUsageRecord: Codable {
    var count: Int
    var lastUsedAt: TimeInterval
}

@MainActor
final class ActionUsageStore {
    static let shared = ActionUsageStore()

    private let defaults: UserDefaults
    private let storeKey = "launcher.usage.records"
    private var records: [String: ActionUsageRecord]

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if
            let raw = defaults.data(forKey: storeKey),
            let decoded = try? JSONDecoder().decode([String: ActionUsageRecord].self, from: raw)
        {
            records = decoded
        } else {
            records = [:]
        }
    }

    func recordExecution(for id: String) {
        let now = Date().timeIntervalSince1970
        var record = records[id] ?? ActionUsageRecord(count: 0, lastUsedAt: now)
        record.count += 1
        record.lastUsedAt = now
        records[id] = record
        persist()
    }

    func rankingBoost(for id: String) -> Double {
        guard let record = records[id] else {
            return 0
        }

        let now = Date().timeIntervalSince1970
        let ageSeconds = max(0, now - record.lastUsedAt)
        let recency = 30.0 * exp(-ageSeconds / (60 * 60 * 24 * 3))
        let frequency = Double(record.count) * 6.0
        return frequency + recency
    }

    private func persist() {
        guard let encoded = try? JSONEncoder().encode(records) else {
            return
        }
        defaults.set(encoded, forKey: storeKey)
    }
}
