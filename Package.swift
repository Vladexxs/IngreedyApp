// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Ingreedy",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Ingreedy",
            targets: ["Ingreedy"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Ingreedy",
            dependencies: []),
        .testTarget(
            name: "IngreedyTests",
            dependencies: ["Ingreedy"]),
    ]
) 