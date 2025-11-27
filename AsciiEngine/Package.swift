// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AsciiEngine",
    products: [
        .library(
            name: "AsciiEngine",
            type: .dynamic,
            targets: ["CAsciiCore"]
        ),
    ],
    targets: [
        .target(
            name: "CAsciiCore",
            dependencies: [],
            path: "Sources/CAsciiCore"
        )
    ]
)
