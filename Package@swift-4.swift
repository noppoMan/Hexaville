// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Hexaville",
    products: [
        .library(name: "HexavilleCore", targets: ["HexavilleCore"]),
        .executable(name: "hexaville", targets: ["Hexaville"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-aws/s3.git", .upToNextMajor(from: "1.0.2")),
        .package(url: "https://github.com/swift-aws/lambda.git", .upToNextMajor(from: "1.0.2")),
        .package(url: "https://github.com/swift-aws/iam.git", .upToNextMajor(from: "1.0.2")),
        .package(url: "https://github.com/swift-aws/apigateway.git", .upToNextMajor(from: "1.0.2")),
        .package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", .upToNextMajor(from: "16.0.0")),
        .package(url: "https://github.com/jakeheis/SwiftCLI.git", .upToNextMajor(from: "3.1.0")),
        .package(url: "https://github.com/behrang/YamlSwift.git", .upToNextMajor(from: "3.0.0"))
    ],
    targets: [
        .target(name: "HexavilleCore", dependencies: [
            "SwiftAWSS3",
            "SwiftAWSLambda",
            "SwiftAWSIam",
            "SwiftAWSApigateway",
            "SwiftyJSON",
            "SwiftCLI",
            "Yaml",
        ]),
        .target(name: "Hexaville", dependencies: ["HexavilleCore"]),
        .testTarget(name: "HexavilleTests", dependencies: ["HexavilleCore"])
    ]
)
