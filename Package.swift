// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "SHMRFinanceApp",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.5.2")
    ]
)
