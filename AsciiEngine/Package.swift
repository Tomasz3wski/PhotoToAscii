// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AsciiEngine",
    products: [
        .library(
            name: "AsciiEngine",
            targets: ["CAsciiCore"]
        ),
    ],
    targets: [
        .target(
            name: "ARM_ASM",
            path: "Sources/ARM_ASM",
            sources: ["conversion_loop.S"],
            publicHeadersPath: "include"
        ),
        .target(
            name: "CAsciiCore",
            dependencies: ["ARM_ASM"],
            path: "Sources/CAsciiCore",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("../ARM_ASM/include")
            ]
        )
    ]
)
