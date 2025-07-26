// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "StartAnimation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "StartAnimation", targets: ["StartAnimation"]),
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.5.2")
    ],
    targets: [
        .target(
            name: "StartAnimation",
            dependencies: [
                .product(name: "Lottie", package: "lottie-ios")
            ],
        )
    ]
)
