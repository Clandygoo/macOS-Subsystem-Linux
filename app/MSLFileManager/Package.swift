// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MSLFileManager",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MSLFileManager", targets: ["MSLFileManager"])
    ],
    targets: [
        .executableTarget(
            name: "MSLFileManager",
            path: "MSLFileManager",
            linkerSettings: [
                .linkedFramework("DiskArbitration"),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .testTarget(
            name: "MSLFileManagerTests",
            dependencies: ["MSLFileManager"],
            path: "MSLFileManagerTests"
        )
    ]
)
