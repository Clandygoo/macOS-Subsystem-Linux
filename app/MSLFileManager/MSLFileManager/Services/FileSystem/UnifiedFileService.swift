import Foundation

actor UnifiedFileService {
    private let vmCommand = VMCommandService()

    func listLocalContents(at url: URL) throws -> [FileItem] {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [
                .isDirectoryKey,
                .fileSizeKey,
                .contentModificationDateKey,
                .typeIdentifierKey,
                .isHiddenKey
            ],
            options: [.skipsHiddenFiles]
        )

        return contents.map { FileItem.local(url: $0) }
    }

    func listRemoteContents(at path: String) async throws -> [FileItem] {
        try await vmCommand.listDirectory(path)
    }

    func readLocalFile(at url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    func readRemoteFile(at path: String) async throws -> String {
        try await vmCommand.readFile(path)
    }

    func writeLocalFile(at url: URL, data: Data) throws {
        try data.write(to: url)
    }

    func writeRemoteFile(at path: String, content: String) async throws {
        try await vmCommand.writeFile(path, content: content)
    }
}
