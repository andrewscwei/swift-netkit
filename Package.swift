// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "NetKit",
  platforms: [.iOS(.v11)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "NetKit",
      targets: ["NetKit"]),
  ],
  dependencies: [
    .package(path: "../BaseKit"),
    .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.4.3"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "NetKit",
      dependencies: ["BaseKit", "Alamofire"]),
    .testTarget(
      name: "NetKitTests",
      dependencies: ["NetKit"]),
  ]
)
