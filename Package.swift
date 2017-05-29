// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "Hexaville",
    targets: [
        Target(name: "HexavilleCore"),
        Target(name: "Hexaville", dependencies: ["HexavilleCore"])
    ],
    dependencies: [
        .Package(url: "https://github.com/noppoMan/aws-sdk-swift.git", majorVersion: 0, minor: 1),
        .Package(url: "https://github.com/jakeheis/SwiftCLI.git", majorVersion: 3),
        .Package(url: "https://github.com/behrang/YamlSwift.git", majorVersion: 3)
    ]
)
