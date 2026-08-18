import Foundation

actor LimaService {
    private let limactlPath = Constants.limactlPath
    private let instanceName = Constants.vmInstanceName

    func shell(_ command: String, timeout: TimeInterval = 30) async throws -> (stdout: String, stderr: String) {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: limactlPath)
            process.arguments = ["shell", instanceName, "--", "bash", "-c", command]

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            let timer = DispatchSource.makeTimerSource()
            timer.schedule(deadline: .now() + timeout)
            timer.setEventHandler {
                process.terminate()
            }
            timer.resume()

            process.terminationHandler = { _ in
                timer.cancel()
                let out = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let err = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                continuation.resume(returning: (out, err))
            }

            do {
                try process.run()
            } catch {
                timer.cancel()
                continuation.resume(throwing: error)
            }
        }
    }

    func startVM() async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: limactlPath)
        process.arguments = ["start", instanceName]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw VMError.startFailed(output)
        }
    }

    func stopVM() async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: limactlPath)
        process.arguments = ["stop", instanceName]

        try process.run()
        process.waitUntilExit()
    }

    func isRunning() async -> Bool {
        let result = try? await shell("echo running", timeout: 10)
        return result?.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "running"
    }

    func getStatus() async -> VMStatus {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: limactlPath)
        process.arguments = ["list", "--format", "json"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return .unknown
            }

            guard let status = json["status"] as? String else {
                return .unknown
            }

            switch status {
            case "Running": return .running
            case "Stopped": return .stopped
            case "Starting": return .starting
            default: return .unknown
            }
        } catch {
            return .error(error.localizedDescription)
        }
    }
}

enum VMError: Error, LocalizedError {
    case startFailed(String)
    case notRunning
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .startFailed(let msg): return "Failed to start VM: \(msg)"
        case .notRunning: return "VM is not running"
        case .commandFailed(let msg): return "Command failed: \(msg)"
        }
    }
}
