// swift-tools-version:6.0

import PackageDescription

let package = Package(
  name: "NetKit",
  platforms: [
    .macOS(.v12),
    .iOS(.v15),
    .tvOS(.v15),
    .watchOS(.v8),
  ],
  products: [
    .library(
      name: "NetKit",
      targets: [
        "NetKit",
      ]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.0.0")),
    .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", .upToNextMajor(from: "5.0.0")),
  ],
  targets: [
    .target(
      name: "NetKit",
      dependencies: [
        "Alamofire",
        "SwiftyJSON",
      ],
      path: "Sources"
    ),
    .testTarget(
      name: "NetKitTests",
      dependencies: [
        "NetKit",
      ],
      path: "Tests"
    ),
  ]
)
