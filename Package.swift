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
            checksum: "7bdb6f04caff8ef7a7ab0bd24cce551bd2127b0a372020ab8830380df3cc3e72"
        )
    ]
)
