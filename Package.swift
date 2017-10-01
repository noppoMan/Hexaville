// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "Hexaville",
    targets: [
        Target(name: "HexavilleCore"),
        Target(name: "Hexaville", dependencies: ["HexavilleCore"])
    ],
    dependencies: [
        .Package(url: "https://github.com/swift-aws/s3.git", majorVersion: 0, minor: 3),
        .Package(url: "https://github.com/swift-aws/lambda.git", majorVersion: 0, minor: 3),
        .Package(url: "https://github.com/swift-aws/iam.git", majorVersion: 0, minor: 3),
        .Package(url: "https://github.com/swift-aws/apigateway.git", majorVersion: 0, minor: 3),
        .Package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", majorVersion: 16),
        .Package(url: "https://github.com/jakeheis/SwiftCLI.git", majorVersion: 3, minor: 1),
        .Package(url: "https://github.com/behrang/YamlSwift.git", majorVersion: 3)
    ]
)
