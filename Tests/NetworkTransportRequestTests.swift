import XCTest
@testable import NetKit

class NetworkTransportRequestTests: XCTestCase {
  enum MockEndpoint: NetworkEndpoint {
    struct Params: Codable {
      let foo: String?
      let bar: String?
    }

    struct Payload: Codable {
      let args: Params?
      let json: Params?
    }

    case get(params: [String: Sendable]? = nil)
    case delete(params: [String: Sendable]? = nil)
    case post(params: [String: Sendable]? = nil)
    case put(params: [String: Sendable]? = nil)
    case patch(params: [String: Sendable]? = nil)
    case statusCode(code: Int)

    var pathDescriptor: PathDescriptor {
      switch self {
      case .get:
        return (.get, "/get")
      case .delete:
        return (.delete, "/delete")
      case .post:
        return (.post, "/post")
      case .put:
        return (.put, "/put")
      case .patch:
        return (.patch, "/patch")
      case .statusCode(let code):
        return (.get, "/status/\(code)")
      }
    }

    var parameters: [String: any Sendable]? {
      switch self {
      case
        let .get(params),
        let .delete(params),
        let .post(params),
        let .put(params),
        let .patch(params):
        return params
      default:
        return nil
      }
    }

    static var host: String { "https://httpbin.org" }
  }

  let timeout: TimeInterval = 5

  func testDecodableGet() {
    let networkTransport = NetworkTransport()
    let params = MockEndpoint.Params(foo: "foo", bar: "bar")
    let expectation = XCTestExpectation()

    Task {
      let data: MockEndpoint.Payload = try await networkTransport.request(MockEndpoint.get(params: ["foo": "foo", "bar": "bar"]))
      XCTAssertTrue(data.args?.foo == params.foo)
      XCTAssertTrue(data.args?.bar == params.bar)
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: timeout)
  }

  func testDecodablePost() {
    let networkTransport = NetworkTransport()
    let params = MockEndpoint.Params(foo: "foo", bar: "bar")
    let expectation = XCTestExpectation()

    Task {
      let data: MockEndpoint.Payload = try await networkTransport.request(MockEndpoint.post(params: ["foo": "foo", "bar": "bar"]))
      XCTAssertTrue(data.json?.foo == params.foo)
      XCTAssertTrue(data.json?.bar == params.bar)
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: timeout)
  }

  func testDecodablePut() {
    let networkTransport = NetworkTransport()
    let params = MockEndpoint.Params(foo: "foo", bar: "bar")
    let expectation = XCTestExpectation()

    Task {
      let data: MockEndpoint.Payload = try await networkTransport.request(MockEndpoint.put(params: ["foo": "foo", "bar": "bar"]))
      XCTAssertTrue(data.json?.foo == params.foo)
      XCTAssertTrue(data.json?.bar == params.bar)
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: timeout)
  }

  func testDecodablePatch() {
    let networkTransport = NetworkTransport()
    let params = MockEndpoint.Params(foo: "foo", bar: "bar")
    let expectation = XCTestExpectation()

    Task {
      let data: MockEndpoint.Payload = try await networkTransport.request(MockEndpoint.patch(params: ["foo": "foo", "bar": "bar"]))
      XCTAssertTrue(data.json?.foo == params.foo)
      XCTAssertTrue(data.json?.bar == params.bar)
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: timeout)
  }

  func testDecodableDelete() {
    let networkTransport = NetworkTransport()
    let params = MockEndpoint.Params(foo: "foo", bar: "bar")
    let expectation = XCTestExpectation()

    Task {
      let data: MockEndpoint.Payload = try await networkTransport.request(MockEndpoint.delete(params: ["foo": "foo", "bar": "bar"]))
      XCTAssertTrue(data.args?.foo == params.foo)
      XCTAssertTrue(data.args?.bar == params.bar)
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: timeout)
  }

  func testEmpty200() {
    let networkTransport = NetworkTransport()
    let expectation = XCTestExpectation()

    Task {
      try await networkTransport.request(MockEndpoint.statusCode(code: 200))
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: timeout)
  }

  func testEmpty204() {
    let networkTransport = NetworkTransport()
    let expectation = XCTestExpectation()

    Task {
      try await networkTransport.request(MockEndpoint.statusCode(code: 204))
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: timeout)
  }

  func testEmpty400() {
    let networkTransport = NetworkTransport()
    let expectation = XCTestExpectation()

    Task {
      do {
        try await networkTransport.request(MockEndpoint.statusCode(code: 400))
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
        try await networkTransport.request(MockEndpoint.statusCode(code: 401))
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
        try await networkTransport.request(MockEndpoint.statusCode(code: 429))
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
        try await networkTransport.request(MockEndpoint.statusCode(code: 500))
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
