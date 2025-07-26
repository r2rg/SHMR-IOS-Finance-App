// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Utilities",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "PieChart",
            type: .static,
            targets: ["PieChart"]),
    ],
    targets: [
        .target(
            name: "PieChart",
            dependencies: []),
    ]
)
