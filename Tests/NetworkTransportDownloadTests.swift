import XCTest
@testable import NetKit

class NetworkTransportDownloadTests: XCTestCase {

  enum MockEndpoint: NetworkEndpoint {
    case image

    var pathDescriptor: PathDescriptor {
      switch self {
      case .image: return (.get, "/image")
      }
    }

    static var host: String { "https://httpbin.org" }
  }

  func testImageDownload() {
    let expectation = XCTestExpectation(description: "[GET] should download image with response status code 200")

    let networkTransport = NetworkTransport()

    networkTransport.download(from: MockEndpoint.image, to: FileManager.default.temporaryDirectory) { result in
      XCTAssertNoThrow(result.get)
      expectation.fulfill()
    }

    wait(for: [
      expectation,
    ], timeout: 5)
  }
}
