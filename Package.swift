// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Hexaville",
    products: [
        .library(name: "HexavilleCore", targets: ["HexavilleCore"]),
        .executable(name: "hexaville", targets: ["Hexaville"])
    ],
    dependencies: [
        .package(url: "https://github.com/jakeheis/SwiftCLI.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/jpsim/Yams.git", .upToNextMajor(from: "2.0.0"))
    ],
    targets: [
        .target(name: "HexavilleCore", dependencies: [
            "SwiftCLI",
            "Yams"
        ]),
        .target(name: "Hexaville", dependencies: ["HexavilleCore"]),
        .testTarget(name: "HexavilleTests", dependencies: ["HexavilleCore"])
    ]
)
