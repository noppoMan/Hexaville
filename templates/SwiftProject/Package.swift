// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "{{appName}}",
    dependencies: [
        .Package(url: "https://github.com/noppoMan/HexavilleFramework.git", majorVersion: 0, minor: 1),
    ]
)
