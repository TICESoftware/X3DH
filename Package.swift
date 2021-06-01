// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "X3DH",
    products: [
        .library(
            name: "X3DH",
            targets: ["X3DH"]),
    ],
    dependencies: [
        .package(url: "https://github.com/TICESoftware/Clibsodium.git", from: "1.0.1"),
        .package(url: "https://github.com/TICESoftware/swift-sodium.git", .branch("spmWorkaround")),
        .package(url: "https://github.com/TICESoftware/HKDF.git", .branch("explicitClibsodium")),
    ],
    targets: [
        .target(
            name: "X3DH",
            dependencies: ["Sodium", "HKDF", "Clibsodium"]),
        .testTarget(
            name: "X3DHTests",
            dependencies: ["X3DH", "Sodium", "Clibsodium"]),
    ]
)
