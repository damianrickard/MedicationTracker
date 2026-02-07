// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MedicationTracker",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MedicationTracker",
            path: "Sources/MedicationTracker"
        )
    ]
)
