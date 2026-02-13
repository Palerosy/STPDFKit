// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "STPDFKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "STPDFKit", targets: ["STPDFKit"]),
    ],
    targets: [
        .target(
            name: "STPDFKit",
            dependencies: []
        ),
        .testTarget(
            name: "STPDFKitTests",
            dependencies: ["STPDFKit"]
        ),
    ]
)
