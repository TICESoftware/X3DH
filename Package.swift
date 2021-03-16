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
        .package(url: "https://github.com/TICESoftware/swift-sodium.git", from: "0.9.2"),
        .package(url: "https://github.com/TICESoftware/HKDF.git", from: "1.0.10"),
    ],
    targets: [
        .target(
            name: "X3DH",
            dependencies: ["Sodium", "HKDF"]),
        .testTarget(
            name: "X3DHTests",
            dependencies: ["X3DH", "Sodium"]),
    ]
)
