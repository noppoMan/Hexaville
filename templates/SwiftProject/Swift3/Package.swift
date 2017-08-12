import PackageDescription

let package = Package(
    name: "{{appName}}",
    targets: [
        Target(name: "{{appName}}", dependencies: []),
    ],
    dependencies: [
        .Package(url: "https://github.com/noppoMan/HexavilleFramework.git", majorVersion: 0, minor: 1),
    ]
)
