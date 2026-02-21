import Foundation

enum ShellCommandRunner {
    private static var running = [Process]()

    static func runDetached(_ command: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]

        process.terminationHandler = { finished in
            DispatchQueue.main.async {
                running.removeAll { $0 === finished }
            }
        }

        do {
            try process.run()
            running.append(process)
        } catch {
            return
        }
    }
}
