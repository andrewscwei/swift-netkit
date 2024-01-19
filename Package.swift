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
  .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.8.1")),
  .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", .upToNextMajor(from: "5.0.1")),
]

switch Environment.get() {
case .local:
  break
case .development:
  break
case .production:
  break
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
      dependencies: ["Alamofire", "SwiftyJSON"]),
    .testTarget(
      name: "NetKitTests",
      dependencies: ["NetKit"]),
  ]
)
