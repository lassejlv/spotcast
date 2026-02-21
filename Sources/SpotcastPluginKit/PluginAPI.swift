import Foundation

public struct PluginMetadata: Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let keywords: [String]
    public let iconSystemName: String?
    public let storageNamespace: String?

    public init(
        id: String, title: String, subtitle: String, keywords: [String] = [],
        iconSystemName: String? = nil,
        storageNamespace: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.keywords = keywords
        self.iconSystemName = iconSystemName
        self.storageNamespace = storageNamespace
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

public enum PluginToastStyle: String, Sendable {
    case info
    case success
    case warning
    case error
}

public struct PluginToast: Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let message: String
    public let style: PluginToastStyle
    public let duration: TimeInterval

    public init(
        id: UUID = UUID(),
        title: String,
        message: String,
        style: PluginToastStyle = .info,
        duration: TimeInterval = 2.0
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.style = style
        self.duration = duration
    }
}

public protocol PluginToaster: Sendable {
    func show(_ toast: PluginToast) async
}

public struct PluginContext: Sendable {
    public let values: PluginInputValues
    public let workspacePath: String
    public let storage: any PluginStorage
    public let toaster: any PluginToaster

    public init(
        values: PluginInputValues,
        workspacePath: String,
        storage: any PluginStorage,
        toaster: any PluginToaster
    ) {
        self.values = values
        self.workspacePath = workspacePath
        self.storage = storage
        self.toaster = toaster
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
