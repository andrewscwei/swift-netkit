import XCTest
@testable import NetKit

class NetworkTransportUploadTests: XCTestCase {
  enum MockEndpoint: NetworkEndpoint {
    struct Params: Codable {
      let foo: String?
      let bar: String?
    }

    struct Payload: Codable {
      let form: Params?
      let files: [String: String]?
    }

    case post([String: Sendable])
    case statusCode(code: Int)

    var pathDescriptor: PathDescriptor {
      switch self {
      case .post: return (.post, "/post")
      case .statusCode(let code): return (.post, "/status/\(code)")
      }
    }

    var parameters: [String: any Sendable]? {
      switch self {
      case let .post(params): return params
      default: return nil
      }
    }

    static var host: String { "https://httpbin.org" }
  }

  let timeout: TimeInterval = 5

  func testDecodableResponse() {
    let networkTransport = NetworkTransport()
    let params = MockEndpoint.Params(foo: "foo", bar: "bar")
    let expectation = XCTestExpectation()

    Task {
      let data: MockEndpoint.Payload = try await networkTransport.upload(MockEndpoint.post(["foo": "foo", "bar": "bar", "file": Data("Hello, World!".utf8)]))
      XCTAssertTrue(data.form?.foo == params.foo)
      XCTAssertTrue(data.form?.bar == params.bar)
      XCTAssertTrue(data.files?["file"] == "Hello, World!")
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: timeout)
  }

  func testEmpty200() {
    let networkTransport = NetworkTransport()
    let expectation = XCTestExpectation()

    Task {
      try await networkTransport.upload(MockEndpoint.statusCode(code: 200))
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: timeout)
  }

  func testEmpty204() {
    let networkTransport = NetworkTransport()
    let expectation = XCTestExpectation()

    Task {
      try await networkTransport.upload(MockEndpoint.statusCode(code: 204))
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: timeout)
  }

  func testEmpty400() {
    let networkTransport = NetworkTransport()
    let expectation = XCTestExpectation()

    Task {
      do {
        try await networkTransport.upload(MockEndpoint.statusCode(code: 400))
        XCTFail()
      }
      catch {
        switch error {
        case NetworkError.client:
          expectation.fulfill()
        default:
          XCTFail()
        }
      }
    }

    wait(for: [expectation], timeout: timeout)
  }

  func testEmpty401() {
    let networkTransport = NetworkTransport()
    let expectation = XCTestExpectation()

    Task {
      do {
        try await networkTransport.upload(MockEndpoint.statusCode(code: 401))
        XCTFail()
      }
      catch {
        switch error {
        case NetworkError.unauthorized:
          expectation.fulfill()
        default:
          XCTFail()
        }
      }
    }

    wait(for: [expectation], timeout: timeout)
  }

  func testEmpty429() {
    let networkTransport = NetworkTransport()
    let expectation = XCTestExpectation()

    Task {
      do {
        try await networkTransport.upload(MockEndpoint.statusCode(code: 429))
        XCTFail()
      }
      catch {
        switch error {
        case NetworkError.tooManyRequests:
          expectation.fulfill()
        default:
          XCTFail()
        }
      }
    }

    wait(for: [expectation], timeout: timeout)
  }

  func testEmpty500() {
    let networkTransport = NetworkTransport()
    let expectation = XCTestExpectation()

    Task {
      do {
        try await networkTransport.upload(MockEndpoint.statusCode(code: 500))
        XCTFail()
      }
      catch {
        switch error {
        case NetworkError.server:
          expectation.fulfill()
        default:
          XCTFail()
        }
      }
    }

    wait(for: [expectation], timeout: timeout)
  }
}
