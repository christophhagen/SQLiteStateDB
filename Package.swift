// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "SQLiteStateDB",
    products: [
        .library(
            name: "SQLiteDB",
            targets: ["SQLiteDB"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.4"),
        .package(url: "https://github.com/christophhagen/StateModel.git", from: "4.0.0"),
        .package(url: "https://github.com/christophhagen/BinaryCodable.git", from: "3.1.0"),
    ],
    targets: [
        .target(
            name: "SQLiteDB",
        dependencies: [
            .product(name: "SQLite", package: "SQLite.swift"),
            .product(name: "StateModel", package: "StateModel"),
        ]),
        .testTarget(
            name: "SQLiteDBTests",
            dependencies: [
                "SQLiteDB",
                .product(name: "BinaryCodable", package: "BinaryCodable"),
            ]
        ),
    ]
)
