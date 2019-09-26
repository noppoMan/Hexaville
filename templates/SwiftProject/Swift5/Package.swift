// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "{{appName}}",
    dependencies: [
        .package(url: "https://github.com/noppoMan/HexavilleFramework.git", .upToNextMajor(from: "1.0.0-rc.4")),
    ],
    targets: [
        .target(name: "{{appName}}", dependencies: ["HexavilleFramework"]),
    ]
)
