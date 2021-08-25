import XCTest
import Alamofire
@testable import NetKit

class NetworkTransportUploadTests: XCTestCase {

  enum MockEndpoint: NetworkEndpoint {
    case post(Parameters)
    case statusCode(code: Int)

    var descriptor: Descriptor {
      switch self {
      case .post: return ("POST", "/post")
      case .statusCode(let code): return ("POST", "/status/\(code)")
      }
    }

    var parameters: Parameters? {
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

    networkTransport.upload(MockEndpoint.post(["foo": "foo", "bar": "bar", "file": Data("Hello, World!".utf8)])) { (result: Result<Payload, Error>) in
      guard let data = try? result.get() else { return XCTFail() }
      XCTAssertTrue(data.form?.foo == params.foo)
      XCTAssertTrue(data.form?.bar == params.bar)
      XCTAssertTrue(data.files?["file"] == "Hello, World!")
      expectationPost.fulfill()
    }

    wait(for: [
      expectationPost,
    ], timeout: 5)
  }

  func testJSONResponse() {
    let expectationPost = XCTestExpectation(description: "[POST] should get response status code 200")

    let networkTransport = NetworkTransport()

    let params: Parameters = [
      "foo": "foo",
      "bar": "bar",
      "file": Data("Hello, World!".utf8),
    ]

    networkTransport.upload(MockEndpoint.post(params)) { (result: Result<Any, Error>) in
      guard let data = try? result.get() as? Parameters, let form = data["form"] as? Parameters, let files = data["files"] as? Parameters else { return XCTFail() }

      XCTAssertTrue(form["foo"] as? String == params["foo"] as? String)
      XCTAssertTrue(form["bar"] as? String == params["bar"] as? String)
      XCTAssertTrue(files["file"] as? String == String(data: params["file"] as! Data, encoding: .utf8))
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

    networkTransport.upload(MockEndpoint.statusCode(code: 200)) { (result: Result<Void, Error>) in
      XCTAssertTrue(result.isSuccess)
      expectation200.fulfill()
    }

    networkTransport.upload(MockEndpoint.statusCode(code: 204)) { (result: Result<Void, Error>) in
      XCTAssertTrue(result.isSuccess)
      expectation204.fulfill()
    }

    networkTransport.upload(MockEndpoint.statusCode(code: 400)) { (result: Result<Void, Error>) in
      switch result {
      case .success: return XCTFail()
      case .failure(let error):
        switch error {
        case NetworkError.client: expectation400.fulfill()
        default: return XCTFail()
        }
      }
    }

    networkTransport.upload(MockEndpoint.statusCode(code: 401)) { (result: Result<Void, Error>) in
      switch result {
      case .success: return XCTFail()
      case .failure(let error):
        switch error {
        case NetworkError.unauthorized: expectation401.fulfill()
        default: return XCTFail()
        }
      }
    }

    networkTransport.upload(MockEndpoint.statusCode(code: 429)) { (result: Result<Void, Error>) in
      switch result {
      case .success: return XCTFail()
      case .failure(let error):
        switch error {
        case NetworkError.tooManyRequests: expectation429.fulfill()
        default: return XCTFail()
        }
      }
    }

    networkTransport.upload(MockEndpoint.statusCode(code: 500)) { (result: Result<Void, Error>) in
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
