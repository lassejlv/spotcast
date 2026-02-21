import Foundation

struct IndexedApp: Identifiable {
    let name: String
    let path: String

    var id: String { path }
}

enum AppIndexer {
    static func installedApps() -> [IndexedApp] {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser.path
        let roots = [
            "/Applications",
            "/System/Applications",
            "\(home)/Applications",
        ]

        var seen = Set<String>()
        var results: [IndexedApp] = []

        for root in roots {
            guard
                let enumerator = fm.enumerator(
                    at: URL(fileURLWithPath: root),
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                )
            else {
                continue
            }

            for case let fileURL as URL in enumerator {
                guard fileURL.pathExtension == "app" else {
                    continue
                }

                let entry = fileURL.lastPathComponent
                let name = String(entry.dropLast(4))
                let key = name.lowercased()
                guard !seen.contains(key) else {
                    continue
                }

                seen.insert(key)
                results.append(IndexedApp(name: name, path: fileURL.path))
            }
        }

        return results.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}
