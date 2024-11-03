import Alamofire
import Foundation

/// A type describing the API endpoint that a `NetworkTransport` uses for
/// making network requests.
public protocol NetworkEndpoint: URLConvertible, CustomStringConvertible {
  typealias PathDescriptor = (method: HTTPMethod, path: String)

  /// A tuple containing the request method and path of the endpoint.
  var pathDescriptor: PathDescriptor { get }

  /// The timeout interval in seconds.
  var timeout: TimeInterval { get }

  /// Headers to set for each request.
  var headers: [String: String] { get }

  /// The parameters of this endpoint. Depending on the request method, these
  /// parameters will either be encoded into the URL as query strings or the
  /// request body as JSON/multipart form parameters.
  var parameters: [String: Any]? { get }

  /// The host URL of the endpoint, (i.e. `https://www.example.com`).
  static var host: String { get }
}

extension NetworkEndpoint {

  /// Request method.
  public var method: HTTPMethod { pathDescriptor.method }

  /// Path of this endpoint (excluding the host, i.e. `/users/get`).
  public var path: String { pathDescriptor.path }
  
  /// Request timeout in seconds.
  public var timeout: TimeInterval { 60 }
  
  /// Request headers.
  public var headers: [String: String] {
    [
      "Accept": "application/json",
      "Content-Type": "application/json",
    ]
  }
  
  public var parameters: [String: Any]? { nil }

  public var description: String { "[\(method.rawValue.uppercased())] \(Self.host)\(path)" }

  public func asURL() throws -> URL {
    guard
      let hostComponents = URLComponents(string: Self.host),
      var urlComponents = URLComponents(string: path)
    else { throw NetworkError.encoding }

    urlComponents.scheme = hostComponents.scheme
    urlComponents.host = hostComponents.host
    urlComponents.port = hostComponents.port

    guard let url = urlComponents.url else { throw NetworkError.encoding }

    return url
  }
}
