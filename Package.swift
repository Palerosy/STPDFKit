// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "STPDFKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "STPDFKit", targets: ["STPDFKit"])
    ],
    targets: [
        .binaryTarget(
            name: "STPDFKit",
            url: "https://github.com/Palerosy/STPDFKit/releases/download/0.1.0/STPDFKit.xcframework.zip",
            checksum: "e3a0afd488a8ec9cb615a753896d78e27936589132a1f3e9373818b89fe5f7d2"
        )
    ]
)
