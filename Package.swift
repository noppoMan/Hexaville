// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Hexaville",
    products: [
        .library(name: "HexavilleCore", targets: ["HexavilleCore"]),
        .executable(name: "hexaville", targets: ["Hexaville"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-aws/aws-sdk-swift.git", .branch("fix-build-error")),
        .package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", .upToNextMajor(from: "17.0.1")),
        .package(url: "https://github.com/jakeheis/SwiftCLI.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/jpsim/Yams.git", .upToNextMajor(from: "1.0.1"))
    ],
    targets: [
        .target(name: "HexavilleCore", dependencies: [
            "S3",
            "Lambda",
            "IAM",
            "APIGateway",
            "SwiftyJSON",
            "SwiftCLI",
            "Yams"
        ]),
        .target(name: "Hexaville", dependencies: ["HexavilleCore"]),
        .testTarget(name: "HexavilleTests", dependencies: ["HexavilleCore"])
    ]
)
