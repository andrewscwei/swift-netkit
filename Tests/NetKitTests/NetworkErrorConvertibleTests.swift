import XCTest
@testable import NetKit

class NetworkErrorConvertibleTests: XCTestCase {
  func testErrorConvertible() {
    struct MockNetworkConvertible: NetworkErrorConvertible {
      func asNetworkError(statusCode: Int? = nil) throws -> NetworkError {
        return .unknown
      }
    }

    XCTAssertNoThrow(try MockNetworkConvertible().asNetworkError())
  }
}
