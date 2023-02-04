// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Lightbox",
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
