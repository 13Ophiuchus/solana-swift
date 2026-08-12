// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "solana-swift-concurrency",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "SolanaSwift",
            targets: ["SolanaSwift"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-crypto",
            "1.0.0"..<"5.0.0"
        ),
        .package(
            url: "https://github.com/21-DOT-DEV/swift-secp256k1",
            from: "0.21.1"
        ),
        .package(
            url: "https://github.com/bitmark-inc/tweetnacl-swiftwrap",
            .upToNextMajor(from: "1.0.0")
        ),
        .package(
            url: "https://github.com/bigearsenal/task-retrying-swift",
            .upToNextMajor(from: "1.0.0")
        ),
    ],
    targets: [
        .target(
            name: "SolanaSwift",
            dependencies: [
                .product(name: "Crypto",          package: "swift-crypto"),
                .product(name: "P256K",           package: "swift-secp256k1"),
                .product(name: "libsecp256k1",    package: "swift-secp256k1"),
                .product(name: "TweetNacl",       package: "tweetnacl-swiftwrap"),
                .product(name: "Task_retrying",   package: "task-retrying-swift"),
            ],
            path: "Sources/SolanaSwift"
        ),
        .testTarget(
            name: "SolanaSwiftTests",
            dependencies: ["SolanaSwift"],
            path: "Tests"
        ),
    ]
)
