// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "a-visual-meditation",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "MeditationView",
            targets: ["MeditationView"]
        )
    ],
    targets: [
        .target(
            name: "MeditationView",
            resources: [
                .copy("shaders")
            ]
        ),
        .executableTarget(
            name: "meditation",
            dependencies: ["MeditationView"]
        )
    ]
)
