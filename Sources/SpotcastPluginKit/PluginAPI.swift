import Foundation

public struct PluginMetadata: Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let keywords: [String]
    public let iconSystemName: String?

    public init(
        id: String, title: String, subtitle: String, keywords: [String] = [],
        iconSystemName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.keywords = keywords
        self.iconSystemName = iconSystemName
    }
}

public enum PluginFieldType: Sendable {
    case text(multiline: Bool)
    case number
    case toggle
    case select(options: [String])
}

public enum PluginFieldValue: Equatable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
}

public struct PluginField: Identifiable, Sendable {
    public let id: String
    public let label: String
    public let placeholder: String?
    public let required: Bool
    public let type: PluginFieldType
    public let defaultValue: PluginFieldValue?

    public init(
        id: String,
        label: String,
        placeholder: String? = nil,
        required: Bool = false,
        type: PluginFieldType,
        defaultValue: PluginFieldValue? = nil
    ) {
        self.id = id
        self.label = label
        self.placeholder = placeholder
        self.required = required
        self.type = type
        self.defaultValue = defaultValue
    }
}

public struct PluginInputValues: Sendable {
    private let storage: [String: PluginFieldValue]

    public init(storage: [String: PluginFieldValue]) {
        self.storage = storage
    }

    public func string(_ id: String) -> String? {
        guard case .string(let value)? = storage[id] else { return nil }
        return value
    }

    public func number(_ id: String) -> Double? {
        guard case .number(let value)? = storage[id] else { return nil }
        return value
    }

    public func bool(_ id: String) -> Bool? {
        guard case .bool(let value)? = storage[id] else { return nil }
        return value
    }
}

public protocol PluginStorage: Sendable {
    func string(forKey key: String) async -> String?
    func number(forKey key: String) async -> Double?
    func bool(forKey key: String) async -> Bool?
    func setString(_ value: String?, forKey key: String) async
    func setNumber(_ value: Double?, forKey key: String) async
    func setBool(_ value: Bool?, forKey key: String) async
    func removeValue(forKey key: String) async
    func allKeys() async -> [String]
}

public struct PluginContext: Sendable {
    public let values: PluginInputValues
    public let workspacePath: String
    public let storage: any PluginStorage

    public init(values: PluginInputValues, workspacePath: String, storage: any PluginStorage) {
        self.values = values
        self.workspacePath = workspacePath
        self.storage = storage
    }
}

public enum PluginExecutionResult: Sendable {
    case none
    case openURL(String)
    case runShell(String)
    case copyToClipboard(String)
    case message(String)
}

public protocol SpotcastPlugin: Sendable {
    var metadata: PluginMetadata { get }
    var fields: [PluginField] { get }
    func run(context: PluginContext) async throws -> PluginExecutionResult
}
