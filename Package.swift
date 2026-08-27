// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ColorKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "ColorKit", targets: ["ColorKit"])],
    targets: [
        .target(name: "ColorKit"),
        .testTarget(name: "ColorKitTests", dependencies: ["ColorKit"])
    ]
)
