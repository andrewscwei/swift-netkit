// swift-tools-version:5.3

import PackageDescription

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

enum Environment: String {
  case local
  case development
  case production

  static func get() -> Environment {
    if let envPointer = getenv("SWIFT_ENV"), let environment = Environment(rawValue: String(cString: envPointer)) {
      return environment
    }
    else if let envPointer = getenv("CI"), String(cString: envPointer) == "true" {
      return .production
    }
    else {
      return .local
    }
  }
}

var dependencies: [Package.Dependency] = [
  .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.4.3")),
  .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", .upToNextMajor(from: "5.0.1")),
]

switch Environment.get() {
case .local:
  dependencies.append(.package(path: "../BaseKit"))
case .development:
  dependencies.append(.package(name: "BaseKit", url: "git@github.com:sybl/swift-basekit", .branch("main")))
case .production:
  dependencies.append(.package(name: "BaseKit", url: "git@github.com:sybl/swift-basekit", from: "0.11.0"))
}

let package = Package(
  name: "NetKit",
  platforms: [.iOS(.v11)],
  products: [
    .library(
      name: "NetKit",
      targets: ["NetKit"]),
  ],
  dependencies: dependencies,
  targets: [
    .target(
      name: "NetKit",
      dependencies: ["BaseKit", "Alamofire", "SwiftyJSON"]),
    .testTarget(
      name: "NetKitTests",
      dependencies: ["NetKit"]),
  ]
)
