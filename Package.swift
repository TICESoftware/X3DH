// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "X3DH",
    products: [
        .library(
            name: "X3DH",
            targets: ["X3DH"]),
    ],
    dependencies: [
         .package(url: "https://github.com/jedisct1/swift-sodium", from: "0.8.0"),
         .package(url: "git@github.com:TICESoftware/HKDF.git", from: "1.0.0"),
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
