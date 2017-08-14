// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "{{appName}}",
    dependencies: [
        .package(url: "https://github.com/noppoMan/HexavilleFramework.git", from: "0.1.0"),
    ],
    targets: [
        .target(name: "{{appName}}", dependencies: ["HexavilleFramework"]),
    ]
)
