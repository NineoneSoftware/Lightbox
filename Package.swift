// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "Lightbox",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "Lightbox",
            targets: ["Lightbox"]),
    ],
    dependencies: [
        .package(url: "http://github.com/Asana/Drawsana", from: Version(0, 9, 4))
    ],
    targets: [
        .target(
            name: "Lightbox",
            dependencies: ["Drawsana"],
            path: "Source"
            )
    ],
    swiftLanguageVersions: [.v5]
)
