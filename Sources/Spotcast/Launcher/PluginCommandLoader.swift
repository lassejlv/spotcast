import Foundation

struct PluginCommand: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let keywords: [String]
    let command: String
}

enum PluginCommandLoader {
    static func load() -> [PluginCommand] {
        let fm = FileManager.default
        let cwd = fm.currentDirectoryPath
        let home = fm.homeDirectoryForCurrentUser.path
        let candidates = [
            "\(cwd)/config/commands.json",
            "\(cwd)/config/commands.toml",
            "\(home)/.spotcast/commands.json",
            "\(home)/.spotcast/commands.toml"
        ]

        var commands: [PluginCommand] = []
        var seen = Set<String>()

        for path in candidates where fm.fileExists(atPath: path) {
            let loaded: [PluginCommand]
            if path.hasSuffix(".json") {
                loaded = loadJSON(path: path)
            } else {
                loaded = loadTOML(path: path)
            }

            for command in loaded where !seen.contains(command.id) {
                seen.insert(command.id)
                commands.append(command)
            }
        }

        return commands
    }

    private static func loadJSON(path: String) -> [PluginCommand] {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return []
        }

        if let root = try? JSONDecoder().decode([JSONCommand].self, from: data) {
            return root.compactMap(toPlugin)
        }

        if let wrapped = try? JSONDecoder().decode(JSONWrappedCommands.self, from: data) {
            return wrapped.commands.compactMap(toPlugin)
        }

        return []
    }

    private static func loadTOML(path: String) -> [PluginCommand] {
        guard let raw = try? String(contentsOfFile: path, encoding: .utf8) else {
            return []
        }

        let lines = raw.components(separatedBy: .newlines)
        var dicts = [[String: String]]()
        var current = [String: String]()

        func flush() {
            guard !current.isEmpty else {
                return
            }
            dicts.append(current)
            current = [:]
        }

        for originalLine in lines {
            let line = originalLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || line.hasPrefix("#") {
                continue
            }

            if line == "[[command]]" || line == "[[commands]]" {
                flush()
                continue
            }

            guard let separator = line.firstIndex(of: "=") else {
                continue
            }

            let key = String(line[..<separator]).trimmingCharacters(in: .whitespacesAndNewlines)
            let value = String(line[line.index(after: separator)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            current[key] = value
        }

        flush()

        return dicts.compactMap { dict in
            guard let title = unquote(dict["title"]), let command = unquote(dict["command"]) else {
                return nil
            }

            let id = unquote(dict["id"]) ?? makeID(title: title)
            let subtitle = unquote(dict["subtitle"]) ?? "Run command"
            let keywords = parseArray(dict["keywords"]) ?? []

            return PluginCommand(id: id, title: title, subtitle: subtitle, keywords: keywords, command: command)
        }
    }

    private static func parseArray(_ raw: String?) -> [String]? {
        guard let raw else {
            return nil
        }

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("["), trimmed.hasSuffix("]") else {
            return nil
        }

        let body = String(trimmed.dropFirst().dropLast())
        if body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }

        return body
            .split(separator: ",")
            .compactMap { unquote(String($0).trimmingCharacters(in: .whitespacesAndNewlines)) }
    }

    private static func unquote(_ raw: String?) -> String? {
        guard let raw else {
            return nil
        }

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count >= 2, trimmed.hasPrefix("\""), trimmed.hasSuffix("\"") {
            return String(trimmed.dropFirst().dropLast())
        }

        if trimmed.count >= 2, trimmed.hasPrefix("'"), trimmed.hasSuffix("'") {
            return String(trimmed.dropFirst().dropLast())
        }

        return trimmed.isEmpty ? nil : trimmed
    }

    private static func toPlugin(_ command: JSONCommand) -> PluginCommand? {
        guard !command.title.isEmpty, !command.command.isEmpty else {
            return nil
        }

        return PluginCommand(
            id: command.id ?? makeID(title: command.title),
            title: command.title,
            subtitle: command.subtitle ?? "Run command",
            keywords: command.keywords ?? [],
            command: command.command
        )
    }

    private static func makeID(title: String) -> String {
        title.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}

private struct JSONWrappedCommands: Decodable {
    let commands: [JSONCommand]
}

private struct JSONCommand: Decodable {
    let id: String?
    let title: String
    let subtitle: String?
    let keywords: [String]?
    let command: String
}
