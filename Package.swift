// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "IM02Core",
    platforms: [.macOS(.v13)],
    products: [.library(name: "IM02Core", targets: ["IM02Core"])],
    targets: [
        .target(name: "IM02Core", path: "Elektronika IM-02 — Nu, Pogodi", exclude: ["AppDelegate.swift", "SceneDelegate.swift", "Presentation", "Infrastructure", "Resources", "Assets.xcassets", "Base.lproj", "Info.plist"], sources: ["Domain", "Application"]),
        .testTarget(name: "IM02CoreTests", dependencies: ["IM02Core"], path: "Tests")
    ]
)
