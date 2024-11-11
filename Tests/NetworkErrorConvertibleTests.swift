import XCTest
@testable import NetKit

class NetworkErrorConvertibleTests: XCTestCase {
  func testErrorConvertible() {
    struct MockNetworkConvertible: NetworkErrorConvertible {
      func asNetworkError(statusCode: Int? = nil, validationError: NetworkError? = nil) throws -> NetworkError {
        return .unknown
      }
    }

    XCTAssertNoThrow(try MockNetworkConvertible().asNetworkError())
  }
}
