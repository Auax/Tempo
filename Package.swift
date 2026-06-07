// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Tempo",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "Tempo", targets: ["Tempo"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/rism-digital/verovio.git",
            revision: "43f806031bfff2c64003fc8ddd9910820445f6ab"
        ),
        .package(
            url: "https://github.com/weichsel/ZIPFoundation.git",
            exact: "0.9.20"
        )
    ],
    targets: [
        .executableTarget(
            name: "Tempo",
            dependencies: [
                .product(name: "VerovioToolkit", package: "verovio"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ],
            path: "Sources/Tempo",
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("CoreMIDI"),
                .linkedFramework("WebKit")
            ]
        ),
        .testTarget(
            name: "TempoTests",
            dependencies: ["Tempo"],
            path: "Tests/TempoTests"
        )
    ],
    swiftLanguageModes: [.v5]
)
