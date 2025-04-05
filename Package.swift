// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SDR",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "SDR",
            targets: ["SDR"]),
    ],
    dependencies: [
        // Remove SoapySDR package dependency as we'll use the system library
    ],
    targets: [
        .target(
            name: "SDR",
            dependencies: [],
            path: "Sources",
            linkerSettings: [
                .linkedLibrary("SoapySDR", .when(platforms: [.macOS])),
                .unsafeFlags(["-L/opt/homebrew/lib"]), // Path to Homebrew libraries
                .unsafeFlags(["-I/opt/homebrew/include"]) // Path to Homebrew headers
            ]),
        .testTarget(
            name: "SDRTests",
            dependencies: ["SDR"]),
    ]
) 