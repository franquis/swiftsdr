// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SDR",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SDR",
            targets: ["SDR"]),
        .executable(
            name: "SDRApp",
            targets: ["SDRApp"])
    ],
    dependencies: [
    ],
    targets: [
        .systemLibrary(
            name: "SoapySDR",
            path: "SDR/Headers",
            pkgConfig: "soapysdr",
            providers: [
                .brew(["soapysdr"])
            ]
        ),
        .target(
            name: "SDR",
            dependencies: ["SoapySDR"],
            path: "SDR",
            sources: ["Sources"],
            resources: [
                .process("SDR.entitlements"),
                .process("Assets.xcassets")
            ],
            cSettings: [
                .headerSearchPath("Headers"),
                .define("SWIFT_PACKAGE"),
                .define("_LIBCPP_DISABLE_AVAILABILITY")
            ],
            swiftSettings: [
                .define("SWIFT_PACKAGE")
            ],
            linkerSettings: [
                .linkedLibrary("SoapySDR", .when(platforms: [.macOS])),
                .unsafeFlags(["-L/opt/homebrew/lib"])
            ]),
        .executableTarget(
            name: "SDRApp",
            dependencies: ["SDR", "SoapySDR"],
            path: "SDRApp",
            resources: [
                .process("Assets.xcassets")
            ],
            linkerSettings: [
                .linkedLibrary("SoapySDR", .when(platforms: [.macOS])),
                .unsafeFlags(["-L/opt/homebrew/lib"])
            ])
    ]
) 