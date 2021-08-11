// © Sybl

import Alamofire
import BaseKit
import Foundation

/// Types conforming to this protocol governs certain behaviors of a `NetworkTransport` and intercepts its requests
/// prior to placing them.
public protocol NetworkTransportPolicy: Alamofire.RequestInterceptor {

  /// Host to apply to every request placed by the `NetworkTransport` using this policy.
  var host: String? { get }

  /// Headers to attach to every request placed by the `NetworkTransport` using this policy.
  var headers: [String: String] { get }

  /// Parses the decoded data of the response with a valid status code upon a completed request and returns a `Result`.
  ///
  /// - Parameters:
  ///   - data: The decoded data of the response.
  ///   - statusCode: The HTTP status code of the response.
  ///
  /// - Returns: The `Result`.
  func parseResponse<T>(_ data: T, statusCode: Int) -> Result<T, NetworkError>
}

extension NetworkTransportPolicy {

  public var host: String? { nil }

  public var headers: [String: String] { [:] }

  public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
    var urlRequest = urlRequest

    if
      let host = host,
      let url = urlRequest.url,
      let customComponents = URLComponents(string: host),
      var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
    {
      components.scheme = customComponents.scheme
      components.host = customComponents.host
      components.port = customComponents.port

      urlRequest.url = components.url
    }

    for (key, value) in headers {
      urlRequest.setValue(value, forHTTPHeaderField: key)
    }

    completion(.success(urlRequest))
  }

  /// Parses the decoded data of the response with a valid status code upon a completed request and returns a `Result`.
  /// If the decoded data conforms to `ErrorConvertible` and the status code is within the range of `400` to `599`, a
  /// failure will be returned with the error.
  ///
  /// - Parameters:
  ///   - data: The decoded data of the response.
  ///   - statusCode: The HTTP status code of the response.
  ///
  /// - Returns: The `Result`.
  public func parseResponse<T>(_ data: T, statusCode: Int) -> Result<T, NetworkError> {
    let error = try? (data as? ErrorConvertible)?.asError()

    switch statusCode {
    case 401: return .failure(.unauthorized(code: statusCode, cause: error))
    case 429: return .failure(.tooManyRequests(code: statusCode, cause: error))
    case 400..<499: return .failure(.client(code: statusCode, cause: error))
    case 500..<599: return .failure(.server(code: statusCode, cause: error))
    default:
      if let error = error {
        return .failure(.client(code: statusCode, cause: error))
      }
      else {
        return .success(data)
      }
    }
  }
}
