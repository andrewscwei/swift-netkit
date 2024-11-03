// swift-tools-version:5.5

import PackageDescription

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

#if canImport(XCTest)
let isRunningTests = true
#else
let isRunningTests = false
#endif

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
      path: "Sources",
      swiftSettings: isRunningTests ? [
        .define("NETKIT_DEBUG"),
      ] : [

      ]
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
