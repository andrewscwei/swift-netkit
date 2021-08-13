// © Sybl

import Alamofire
import BaseKit
import Foundation

/// Types conforming to this protocol governs certain behaviors of a `NetworkTransport` and
/// intercepts its requests prior to placing them.
public protocol NetworkTransportPolicy: Alamofire.RequestInterceptor {

  /// Replaces the host for the specified `URLRequest` and `Session`. Provide a successful `Result`
  /// of `nil` to leave the original host untouched.
  func resolveHost(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<String?, Error>) -> Void)

  /// Modifies the headers for the specified `URLRequest` and `Session`. Headers are added to the
  /// current request.
  func resolveHeaders(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<[String: String], Error>) -> Void)

  /// Parses the decoded data of the response with a valid status code upon a completed request and
  /// returns a `Result`.
  ///
  /// - Parameters:
  ///   - data: The decoded data of the response.
  ///   - statusCode: The HTTP status code of the response.
  ///
  /// - Returns: The `Result`.
  func parseResponse<T>(_ data: T, statusCode: Int) -> Result<T, Error>
}

extension NetworkTransportPolicy {

  public func resolveHost(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<String?, Error>) -> Void) {
    completion(.success(nil))
  }

  public func resolveHeaders(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<[String: String], Error>) -> Void) {
    completion(.success([:]))
  }

  public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
    var urlRequest = urlRequest

    resolveHost(urlRequest, for: session) { hostResult in
      switch hostResult {
      case .failure(let error): return completion(.failure(error))
      case .success(let host):
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

        resolveHeaders(urlRequest, for: session) { headersResult in
          switch headersResult {
          case .failure(let error): return completion(.failure(error))
          case .success(let headers):
            for (key, value) in headers {
              urlRequest.setValue(value, forHTTPHeaderField: key)
            }

            completion(.success(urlRequest))
          }
        }
      }
    }
  }

  /// Parses the decoded data of the response with a valid status code upon a completed request and
  /// returns a `Result`. If the decoded data conforms to `ErrorConvertible` and the status code is
  /// within the range of `400` to `599`, a failure will be returned with the error.
  ///
  /// - Parameters:
  ///   - data: The decoded data of the response.
  ///   - statusCode: The HTTP status code of the response.
  ///
  /// - Returns: The `Result`.
  public func parseResponse<T>(_ data: T, statusCode: Int) -> Result<T, Error> {
    let error = try? (data as? ErrorConvertible)?.asError()

    switch statusCode {
    case 401: return .failure(NetworkError.unauthorized(code: statusCode, cause: error))
    case 429: return .failure(NetworkError.tooManyRequests(code: statusCode, cause: error))
    case 400..<499: return .failure(NetworkError.client(code: statusCode, cause: error))
    case 500..<599: return .failure(NetworkError.server(code: statusCode, cause: error))
    default:
      if let error = error {
        return .failure(NetworkError.client(code: statusCode, cause: error))
      }
      else {
        return .success(data)
      }
    }
  }
}
