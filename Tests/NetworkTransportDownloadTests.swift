import XCTest
@testable import NetKit

class NetworkTransportDownloadTests: XCTestCase {
  enum MockEndpoint: NetworkEndpoint {
    case image

    var pathDescriptor: PathDescriptor {
      switch self {
      case .image: return (.get, "/image/webp")
      }
    }

    static var host: String { "https://httpbin.org" }
  }

  let timeout: TimeInterval = 5
  
  func testImageDownload() {
    let networkTransport = NetworkTransport()
    let expectation = XCTestExpectation()

    Task {
      try await networkTransport.download(from: MockEndpoint.image, to: FileManager.default.temporaryDirectory)
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: timeout)
  }
}
