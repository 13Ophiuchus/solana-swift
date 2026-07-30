// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SolanaSwift",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v15),
        .tvOS(.v12),
        .watchOS(.v4),
    ],
    products: [
        .library(
            name: "SolanaSwift",
            targets: ["SolanaSwift"]
        ),
    ],
    dependencies: [
        // Main depedencies
        .package(url: "https://github.com/21-DOT-DEV/swift-secp256k1", from: "0.21.1"),
        .package(url: "https://github.com/bitmark-inc/tweetnacl-swiftwrap.git", from: "1.0.2"),
		.package(url: "https://github.com/bigearsenal/task-retrying-swift.git", from: "1.0.1"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),

        // Docs generator
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
		.target(
			name: "SolanaSwift",
			dependencies: [
				.product(name: "TweetNacl", package: "tweetnacl-swiftwrap"),
				.product(name: "P256K", package: "swift-secp256k1"),
				.product(name: "libsecp256k1", package: "swift-secp256k1"),
				.product(name: "Task_retrying", package: "task-retrying-swift"),
				.product(name: "Crypto", package: "swift-crypto"),
			],
			swiftSettings: [
				.unsafeFlags(["-suppress-warnings"])
			]
		),

        .testTarget(
            name: "SolanaSwiftUnitTests",
            dependencies: ["SolanaSwift"],
            resources: [
                .process("Resources/get_all_tokens_info.json"),
            ]
        ),
        .testTarget(
            name: "SolanaSwiftIntegrationTests",
            dependencies: ["SolanaSwift"]
        ),
    ]
)

