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
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "X3DH",
            dependencies: []),
        .testTarget(
            name: "X3DHTests",
            dependencies: ["X3DH"]),
    ]
)
