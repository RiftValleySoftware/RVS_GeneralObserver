// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "RVS_GeneralObserver",
    platforms: [
        .iOS(.v14),
        .tvOS(.v14),
        .macOS(.v11),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "RVS-GeneralObserver",
                 targets: ["RVS_GeneralObserver"]
        )
    ],
    targets: [
        .target(name: "RVS_GeneralObserver"),
        .testTarget(
            name: "RVS_GeneralObserverTest",
            dependencies: ["RVS_GeneralObserver"])
    ]
)
