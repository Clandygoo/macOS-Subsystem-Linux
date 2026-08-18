import Foundation

actor VMCommandService {
    private let lima = LimaService()

    func execute(_ command: String) async throws -> String {
        let result = try await lima.shell(command, timeout: 60)
        guard result.stderr.isEmpty || result.stdout.contains("error") == false else {
            throw VMError.commandFailed(result.stderr)
        }
        return result.stdout
    }

    func listDirectory(_ path: String) async throws -> [FileItem] {
        let command = """
        ls -la "\(path)" 2>/dev/null | awk 'NR>1 {
            is_dir = ($1 ~ /^d/) ? "true" : "false"
            perms = $1
            size = $5
            month = $6
            day = $7
            time = $8
            name = $9
            for(i=10;i<=NF;i++) name = name " " $i
            gsub(/^ +| +$/, "", name)
            printf "%s\\t%s\\t%s\\t%s %s %s\\t%s\\n", name, is_dir, size, month, day, time, perms
        }'
        """

        let output = try await execute(command)
        var items: [FileItem] = []

        for line in output.components(separatedBy: "\n").filter({ !$0.isEmpty }) {
            let parts = line.components(separatedBy: "\t")
            guard parts.count >= 5 else { continue }

            let name = parts[0]
            let isDir = parts[1] == "true"
            let size = Int64(parts[2]) ?? 0
            let dateStr = parts[3]
            let permissions = parts[4]

            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d HH:mm"
            let date = formatter.date(from: dateStr) ?? Date()

            let fullPath = path.hasSuffix("/") ? "\(path)\(name)" : "\(path)/\(name)"

            items.append(.remote(
                path: fullPath,
                name: name,
                isDirectory: isDir,
                size: size,
                modificationDate: date,
                permissions: permissions
            ))
        }

        return items
    }

    func readFile(_ path: String) async throws -> String {
        try await execute("cat \"\(path)\" 2>/dev/null")
    }

    func writeFile(_ path: String, content: String) async throws {
        let escaped = content.replacingOccurrences(of: "'", with: "'\\''")
        _ = try await execute("echo '\(escaped)' > \"\(path)\"")
    }

    func installPackage(_ package: String) async throws -> String {
        try await execute("sudo apt-get install -y \(package) 2>&1 | tail -5")
    }

    func checkNTFSMount(_ path: String) async throws -> Bool {
        let result = try await execute("mount | grep \(path) | grep ntfs")
        return !result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
