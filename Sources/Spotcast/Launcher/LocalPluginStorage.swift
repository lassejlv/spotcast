import Foundation
import SpotcastPluginKit

actor LocalPluginStorage: PluginStorage {
    private enum StoredValue: Codable {
        case string(String)
        case number(Double)
        case bool(Bool)

        private enum Kind: String, Codable {
            case string
            case number
            case bool
        }

        private enum CodingKeys: String, CodingKey {
            case kind
            case string
            case number
            case bool
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let kind = try container.decode(Kind.self, forKey: .kind)
            switch kind {
            case .string:
                self = .string(try container.decode(String.self, forKey: .string))
            case .number:
                self = .number(try container.decode(Double.self, forKey: .number))
            case .bool:
                self = .bool(try container.decode(Bool.self, forKey: .bool))
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case let .string(value):
                try container.encode(Kind.string, forKey: .kind)
                try container.encode(value, forKey: .string)
            case let .number(value):
                try container.encode(Kind.number, forKey: .kind)
                try container.encode(value, forKey: .number)
            case let .bool(value):
                try container.encode(Kind.bool, forKey: .kind)
                try container.encode(value, forKey: .bool)
            }
        }
    }

    private let fileURL: URL
    private var loaded = false
    private var values: [String: StoredValue] = [:]

    init(pluginID: String) {
        let sanitized = pluginID.replacingOccurrences(of: "[^a-zA-Z0-9._-]", with: "_", options: .regularExpression)
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let directory = appSupport
            .appendingPathComponent("spotcast", isDirectory: true)
            .appendingPathComponent("plugin-storage", isDirectory: true)
        self.fileURL = directory.appendingPathComponent("\(sanitized).json")
    }

    func string(forKey key: String) async -> String? {
        await ensureLoaded()
        guard case let .string(value)? = values[key] else {
            return nil
        }
        return value
    }

    func number(forKey key: String) async -> Double? {
        await ensureLoaded()
        guard case let .number(value)? = values[key] else {
            return nil
        }
        return value
    }

    func bool(forKey key: String) async -> Bool? {
        await ensureLoaded()
        guard case let .bool(value)? = values[key] else {
            return nil
        }
        return value
    }

    func setString(_ value: String?, forKey key: String) async {
        await ensureLoaded()
        if let value {
            values[key] = .string(value)
        } else {
            values.removeValue(forKey: key)
        }
        await persist()
    }

    func setNumber(_ value: Double?, forKey key: String) async {
        await ensureLoaded()
        if let value {
            values[key] = .number(value)
        } else {
            values.removeValue(forKey: key)
        }
        await persist()
    }

    func setBool(_ value: Bool?, forKey key: String) async {
        await ensureLoaded()
        if let value {
            values[key] = .bool(value)
        } else {
            values.removeValue(forKey: key)
        }
        await persist()
    }

    func removeValue(forKey key: String) async {
        await ensureLoaded()
        values.removeValue(forKey: key)
        await persist()
    }

    func allKeys() async -> [String] {
        await ensureLoaded()
        return values.keys.sorted()
    }

    private func ensureLoaded() async {
        guard !loaded else {
            return
        }

        defer { loaded = true }

        guard let data = try? Data(contentsOf: fileURL) else {
            values = [:]
            return
        }

        values = (try? JSONDecoder().decode([String: StoredValue].self, from: data)) ?? [:]
    }

    private func persist() async {
        let fm = FileManager.default
        let directory = fileURL.deletingLastPathComponent()
        try? fm.createDirectory(at: directory, withIntermediateDirectories: true)

        guard let data = try? JSONEncoder().encode(values) else {
            return
        }

        try? data.write(to: fileURL, options: .atomic)
    }
}
