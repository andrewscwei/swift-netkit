import XCTest
@testable import NetKit

class NetworkTransportUploadTests: XCTestCase {
  enum MockEndpoint: NetworkEndpoint {
    case post([String: Sendable])
    case statusCode(code: Int)

    var pathDescriptor: PathDescriptor {
      switch self {
      case .post: return (.post, "/post")
      case .statusCode(let code): return (.post, "/status/\(code)")
      }
    }

    var parameters: [String: Any]? {
      switch self {
      case let .post(params): return params
      default: return nil
      }
    }

    static var host: String { "https://httpbin.org" }
  }

  func testDecodableResponse() {
    struct Params: Codable {
      let foo: String?
      let bar: String?
    }

    struct Payload: Codable {
      let form: Params?
      let files: [String: String]?
    }

    let expectationPost = XCTestExpectation(description: "[POST] should get response status code 200")

    let networkTransport = NetworkTransport()
    let params = Params(foo: "foo", bar: "bar")

    Task {
      let data: Payload = try await networkTransport.upload(MockEndpoint.post(["foo": "foo", "bar": "bar", "file": Data("Hello, World!".utf8)]))
      XCTAssertTrue(data.form?.foo == params.foo)
      XCTAssertTrue(data.form?.bar == params.bar)
      XCTAssertTrue(data.files?["file"] == "Hello, World!")
      expectationPost.fulfill()
    }

    wait(for: [
      expectationPost,
    ], timeout: 5)
  }

  func testVoidResponse() {
    let expectation200 = XCTestExpectation(description: "[POST] Should get response status code 200")
    let expectation204 = XCTestExpectation(description: "[POST] Should get response status code 204")
    let expectation400 = XCTestExpectation(description: "[POST] Should get response status code 400")
    let expectation401 = XCTestExpectation(description: "[POST] Should get response status code 401")
    let expectation429 = XCTestExpectation(description: "[POST] Should get response status code 429")
    let expectation500 = XCTestExpectation(description: "[POST] Should get response status code 500")

    let networkTransport = NetworkTransport()

    Task {
      try await networkTransport.upload(MockEndpoint.statusCode(code: 200))
      expectation200.fulfill()
    }

    Task {
      try await networkTransport.upload(MockEndpoint.statusCode(code: 204))
      expectation204.fulfill()
    }

    Task {
      do {
        try await networkTransport.upload(MockEndpoint.statusCode(code: 400))
        XCTFail()
      }
      catch {
        switch error {
        case NetworkError.client:
          expectation400.fulfill()
        default:
          XCTFail()
        }
      }
    }

    Task {
      do {
        try await networkTransport.upload(MockEndpoint.statusCode(code: 401))
        XCTFail()
      }
      catch {
        switch error {
        case NetworkError.unauthorized:
          expectation401.fulfill()
        default:
          XCTFail()
        }
      }
    }

    Task {
      do {
        try await networkTransport.upload(MockEndpoint.statusCode(code: 429))
        XCTFail()
      }
      catch {
        switch error {
        case NetworkError.tooManyRequests:
          expectation429.fulfill()
        default:
          XCTFail()
        }
      }
    }

    Task {
      do {
        try await networkTransport.upload(MockEndpoint.statusCode(code: 500))
        XCTFail()
      }
      catch {
        switch error {
        case NetworkError.server:
          expectation500.fulfill()
        default:
          XCTFail()
        }
      }
    }

    wait(for: [
      expectation200,
      expectation204,
      expectation400,
      expectation401,
      expectation429,
      expectation500,
    ], timeout: 5)
  }
}
