import Foundation

final class VMLifecycleService: ObservableObject {
    @Published var status: VMStatus = .unknown
    @Published var isStarting: Bool = false

    private let lima = LimaService()

    func refreshStatus() async {
        status = await lima.getStatus()
    }

    func start() async {
        guard !isStarting else { return }
        isStarting = true
        defer { isStarting = false }

        status = .starting
        do {
            try await lima.startVM()
            status = .running
        } catch {
            status = .error(error.localizedDescription)
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
