// swift-tools-version:5.3

import PackageDescription

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

enum Environment: String {
  static let `default`: Environment = .local

  case local
  case development
  case production

  static func get() -> Environment {
    if let envPointer = getenv("CI"), String(cString: envPointer) == "true" {
      return .production
    }
    else if let envPointer = getenv("SWIFT_ENV") {
      let env = String(cString: envPointer)
      return Environment(rawValue: env) ?? .default
    }
    else {
      return .default
    }
  }
}

var dependencies: [Package.Dependency] = [
  .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.4.3"),
]

switch Environment.get() {
case .local:
  dependencies.append(.package(path: "../BaseKit"))
case .development:
  dependencies.append(.package(name: "BaseKit", url: "git@github.com:sybl/swift-basekit", .branch("main")))
case .production:
  dependencies.append(.package(name: "BaseKit", url: "git@github.com:sybl/swift-basekit", from: "0.1.0"))
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
      dependencies: ["BaseKit", "Alamofire"]),
    .testTarget(
      name: "NetKitTests",
      dependencies: ["NetKit"]),
  ]
)
