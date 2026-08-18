import Foundation

final class VMLifecycleService: ObservableObject {
    @Published var status: VMStatus = .unknown
    @Published var isStarting: Bool = false
    @Published var startupProgress: Double = 0
    @Published var startupMessage: String = ""

    private let lima = LimaService()

    func refreshStatus() async {
        status = await lima.getStatus()
    }

    func autoStartIfNeeded() async {
        await refreshStatus()
        guard !status.isRunning else { return }
        await start()
    }

    func start() async {
        guard !isStarting else { return }
        isStarting = true
        startupProgress = 0
        defer {
            isStarting = false
            startupProgress = 1.0
        }

        status = .starting

        startupMessage = "Checking VM..."
        startupProgress = 0.1

        try? await Task.sleep(nanoseconds: 300_000_000)

        startupMessage = "Starting virtual machine..."
        startupProgress = 0.2

        do {
            try await lima.startVM()
            startupMessage = "VM is ready"
            startupProgress = 1.0
            status = .running
        } catch {
            status = .error(error.localizedDescription)
            startupMessage = "Failed: \(error.localizedDescription)"
        }
    }

    func stop() async {
        do {
            try await lima.stopVM()
            status = .stopped
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    func restart() async {
        await stop()
        await start()
    }
}
