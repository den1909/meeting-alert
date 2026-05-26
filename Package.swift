// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AirplaneMeetings",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "AirplaneMeetings", targets: ["AirplaneMeetings"])
    ],
    targets: [
        .executableTarget(
            name: "AirplaneMeetings",
            path: "Sources/AirplaneMeetings"
        )
    ]
)
