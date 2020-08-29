// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "RVS_GeneralObserver",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .macOS(.v10_15),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "RVS-GeneralObserver",
                 targets: [
                    "RVS_GeneralObserver"
                    ]
        )
    ],
    targets: [
        .target(
            name: "RVS_GeneralObserver",
            dependencies: []),
        .testTarget(
            name: "RVS_GeneralObserverTest",
            dependencies: ["RVS_GeneralObserver"])
    ]
)
