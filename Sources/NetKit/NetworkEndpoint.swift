// © Sybl

import Alamofire
import Foundation

public protocol NetworkEndpoint: URLRequestConvertible, CustomStringConvertible {

  /// The path of this endpoint (excluding the host, i.e. `/users/get`).
  var path: String { get }

  /// The request method of this endpoint.
  var method: HTTPMethod { get }

  /// The timeout interval in seconds.
  var timeout: TimeInterval { get }

  /// The query parameters of this endpoint. These parameters will be encoded into the request URL
  /// as the `URLRequest` is constructed.
  var queryParameters: Parameters { get }

  /// The body parameters of this endpoint. These parameters will eventually be applied to the
  /// `httpBody` property of the constructed `URLRequest` by the `NetworkTransport`, overwriting the
  /// preexisting `httpBody` value. These parameters are also used during multipart requests.
  var bodyParameters: Parameters { get }

  /// The host URL of the endpoint, (i.e. `https://www.example.com`).
  static var host: String { get }
}

extension NetworkEndpoint {

  public var description: String { "[\(method.rawValue.uppercased())]\(Self.host)\(path)" }

  public func asURLRequest() throws -> URLRequest {
    guard
      let hostComponents = URLComponents(string: Self.host),
      var urlComponents = URLComponents(string: path)
    else { throw NetworkError.encoding }

    urlComponents.scheme = hostComponents.scheme
    urlComponents.host = hostComponents.host
    urlComponents.port = hostComponents.port

    guard let url = urlComponents.url else { throw NetworkError.encoding }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = method.rawValue
    urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.timeoutInterval = timeout
    urlRequest = try URLEncoding.default.encode(urlRequest, with: queryParameters)
    urlRequest = try JSONEncoding.default.encode(urlRequest, with: bodyParameters)

    return urlRequest
  }
}
