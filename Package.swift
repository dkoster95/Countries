// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Countries",
    platforms: [.iOS(.v17),
                .watchOS(.v7),
                .macOS(.v14),
                .tvOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Countries",
            targets: ["Countries"]),
        .library(
            name: "CountriesCore",
            targets: ["CountriesCore"]),
        .library(
            name: "CountriesContainers",
            targets: ["CountriesContainers"])
    ],
    dependencies: [
        .package(url: "https://github.com/dkoster95/CountriesAPI", branch: "main"),
        .package(url: "https://github.com/dkoster95/PelicanSwift.git", from: "3.1.0"),
        .package(url: "https://github.com/dkoster95/Aquarium.git",
                 from: "1.0.2"),
        .package(url: "https://github.com/dkoster95/QHValidator.git",
                 from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Countries",
            dependencies: ["CountriesCore"],
            path: "Sources/UI",
            resources: [
                .process("Resources") // Processes all resources within the 'Resources' folder
            ]),
        .target(
            name: "CountriesContainers",
            dependencies: ["Aquarium",
                           "CountriesCore",
                           "Countries",
                           .product(name: "CountriesAPIContainers", package: "CountriesAPI"),
                           .product(name: "PelicanRepositories", package: "PelicanSwift"),
                           .product(name: "PelicanProtocols", package: "PelicanSwift")],
            
            path: "Sources/Injections"),
        .target(
            name: "CountriesCore",
            dependencies: [.product(name: "CountriesAPI", package: "CountriesAPI"),
                           .product(name: "PelicanProtocols", package: "PelicanSwift"),
                           .product(name: "QHValidator", package: "QHValidator")],
            
            path: "Sources/Core"),
        .testTarget(
            name: "CountriesTests",
            dependencies: ["Countries"]
        ),
    ]
)
