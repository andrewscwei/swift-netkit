// © Sybl

import Alamofire
import BaseKit
import Foundation

/// Types conforming to this protocol dictates certain behaviors of a `NetworkTransport` and
/// intercepts its requests prior to placing them.
public protocol NetworkTransportPolicy: Alamofire.RequestInterceptor {

  /// Replaces the host for the specified `URLRequest` and `Session`. Provide a successful `Result`
  /// of `nil` to leave the original host untouched.
  func resolveHost(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<String?, Error>) -> Void)

  /// Modifies the headers for the specified `URLRequest` and `Session`. Headers are added to the
  /// current request.
  func resolveHeaders(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<[String: String], Error>) -> Void)

  /// Validates the response.
  ///
  /// - Parameter response: The response.
  ///
  /// - Returns: A `Result` indiciating whether validation was a success (with no value) or a 
  ///            failure (with the error).
  func validate(response: HTTPURLResponse) -> Result<Void, Error>
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

  public func validate(response: HTTPURLResponse) -> Result<Void, Error> {
    let statusCode = response.statusCode

    switch statusCode {
    case 401: return .failure(NetworkError.unauthorized(code: statusCode))
    case 429: return .failure(NetworkError.tooManyRequests(code: statusCode))
    case 400..<499: return .failure(NetworkError.client(code: statusCode))
    case 500..<599: return .failure(NetworkError.server(code: statusCode))
    default: return .success
    }
  }
}
