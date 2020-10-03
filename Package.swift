// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iOSDropbox",
    platforms: [
        // This package depends on iOSSignIn-- which needs at least iOS 13.
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "iOSDropbox",
            targets: ["iOSDropbox"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SyncServerII/iOSSignIn.git", .branch("master")),
        .package(url: "https://github.com/SyncServerII/ServerShared.git", .branch("master")),
        .package(url: "https://github.com/SyncServerII/iOSShared.git", .branch("master")),
        .package(url: "https://github.com/crspybits/SwiftyDropbox.git", .branch("master")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "iOSDropbox",
            dependencies: ["iOSSignIn", "ServerShared", "iOSShared", "SwiftyDropbox"],
            resources: [
                .copy("db_x80.png")
            ]
        ),
        .testTarget(
            name: "iOSDropboxTests",
            dependencies: ["iOSDropbox"]),
    ]
)
