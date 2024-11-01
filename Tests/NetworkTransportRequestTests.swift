import XCTest
@testable import NetKit

class NetworkTransportRequestTests: XCTestCase {

  enum MockEndpoint: NetworkEndpoint {
    case get([String: Any])
    case delete([String: Any])
    case post([String: Any])
    case put([String: Any])
    case patch([String: Any])
    case statusCode(code: Int)

    var pathDescriptor: PathDescriptor {
      switch self {
      case .get: return (.get, "/get")
      case .delete: return (.delete, "/delete")
      case .post: return (.post, "/post")
      case .put: return (.put, "/put")
      case .patch: return (.patch, "/patch")
      case .statusCode(let code): return (.get, "/status/\(code)")
      }
    }

    var parameters: [String: Any]? {
      switch self {
      case let .get(params): return params
      case let .delete(params): return params
      case let .post(params): return params
      case let .put(params): return params
      case let .patch(params): return params
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
      let args: Params?
      let json: Params?
    }

    let expectationGet = XCTestExpectation(description: "[GET] Should get response status code 200")
    let expectationDelete = XCTestExpectation(description: "[DELETE] should get response status code 200")
    let expectationPost = XCTestExpectation(description: "[POST] should get response status code 200")
    let expectationPut = XCTestExpectation(description: "[PUT] should get response status code 200")
    let expectationPatch = XCTestExpectation(description: "[PATCH] should get response status code 200")

    let networkTransport = NetworkTransport()
    let params = Params(foo: "foo", bar: "bar")

    networkTransport.request(MockEndpoint.get(["foo": "foo", "bar": "bar"])) { (result: Result<Payload, Error>) in
      guard let data = try? result.get() else { return XCTFail() }
      XCTAssertTrue(data.args?.foo == params.foo)
      XCTAssertTrue(data.args?.bar == params.bar)
      expectationGet.fulfill()
    }

    networkTransport.request(MockEndpoint.delete(["foo": "foo", "bar": "bar"])) { (result: Result<Payload, Error>) in
      guard let data = try? result.get() else { return XCTFail() }
      XCTAssertTrue(data.args?.foo == params.foo)
      XCTAssertTrue(data.args?.bar == params.bar)
      expectationDelete.fulfill()
    }

    networkTransport.request(MockEndpoint.post(["foo": "foo", "bar": "bar"])) { (result: Result<Payload, Error>) in
      guard let data = try? result.get() else { return XCTFail() }
      XCTAssertTrue(data.json?.foo == params.foo)
      XCTAssertTrue(data.json?.bar == params.bar)
      expectationPost.fulfill()
    }

    networkTransport.request(MockEndpoint.put(["foo": "foo", "bar": "bar"])) { (result: Result<Payload, Error>) in
      guard let data = try? result.get() else { return XCTFail() }
      XCTAssertTrue(data.json?.foo == params.foo)
      XCTAssertTrue(data.json?.bar == params.bar)
      expectationPut.fulfill()
    }

    networkTransport.request(MockEndpoint.patch(["foo": "foo", "bar": "bar"])) { (result: Result<Payload, Error>) in
      guard let data = try? result.get() else { return XCTFail() }
      XCTAssertTrue(data.json?.foo == params.foo)
      XCTAssertTrue(data.json?.bar == params.bar)
      expectationPatch.fulfill()
    }

    wait(for: [
      expectationGet,
      expectationDelete,
      expectationPost,
      expectationPut,
      expectationPatch,
    ], timeout: 5)
  }

  func testVoidResponse() {
    let expectation200 = XCTestExpectation(description: "[GET] Should get response status code 200")
    let expectation204 = XCTestExpectation(description: "[GET] Should get response status code 204")
    let expectation400 = XCTestExpectation(description: "[GET] Should get response status code 400")
    let expectation401 = XCTestExpectation(description: "[GET] Should get response status code 401")
    let expectation429 = XCTestExpectation(description: "[GET] Should get response status code 429")
    let expectation500 = XCTestExpectation(description: "[GET] Should get response status code 500")

    let networkTransport = NetworkTransport()

    networkTransport.request(MockEndpoint.statusCode(code: 200)) { (result: Result<Void, Error>) in
      XCTAssertNoThrow(result.get)
      expectation200.fulfill()
    }

    networkTransport.request(MockEndpoint.statusCode(code: 204)) { (result: Result<Void, Error>) in
      XCTAssertNoThrow(result.get)
      expectation204.fulfill()
    }

    networkTransport.request(MockEndpoint.statusCode(code: 400)) { (result: Result<Void, Error>) in
      switch result {
      case .success: return XCTFail()
      case .failure(let error):
        switch error {
        case NetworkError.client: expectation400.fulfill()
        default: return XCTFail()
        }
      }
    }

    networkTransport.request(MockEndpoint.statusCode(code: 401)) { (result: Result<Void, Error>) in
      switch result {
      case .success: return XCTFail()
      case .failure(let error):
        switch error {
        case NetworkError.unauthorized: expectation401.fulfill()
        default: return XCTFail()
        }
      }
    }

    networkTransport.request(MockEndpoint.statusCode(code: 429)) { (result: Result<Void, Error>) in
      switch result {
      case .success: return XCTFail()
      case .failure(let error):
        switch error {
        case NetworkError.tooManyRequests: expectation429.fulfill()
        default: return XCTFail()
        }
      }
    }

    networkTransport.request(MockEndpoint.statusCode(code: 500)) { (result: Result<Void, Error>) in
      switch result {
      case .success: return XCTFail()
      case .failure(let error):
        switch error {
        case NetworkError.server: expectation500.fulfill()
        default: return XCTFail()
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
