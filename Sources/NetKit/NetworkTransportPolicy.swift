// © GHOZT

import Alamofire
import Foundation

/// Types conforming to this protocol dictates certain behaviors of a
/// `NetworkTransport` and intercepts its requests prior to placing them.
public protocol NetworkTransportPolicy: Alamofire.RequestInterceptor {

  /// Replaces the host for the specified `URLRequest`. Provide a successful
  /// `Result` of `nil` to leave the original host untouched.
  func resolveHost(for urlRequest: URLRequest, completion: @escaping (Result<String?, Error>) -> Void)

  /// Modifies the headers for the specified `URLRequest`. Headers are added to
  /// the current request.
  func resolveHeaders(for urlRequest: URLRequest, completion: @escaping (Result<[String: String], Error>) -> Void)

  /// Validates the response.
  ///
  /// - Parameters:
  ///   - response: The response.
  ///
  /// - Returns: A `Result` indicating whether validation was a success (with no
  ///            value) or a failure (with the error).
  func validate(response: HTTPURLResponse) -> Result<Void, Error>

  /// Intercepts and parses the response result, then returns the parsed result
  /// to the client.
  ///
  /// - Parameters:
  ///   - result: The `Result` from the network request initiated by the
  ///             `NetworkTransport`.
  ///   - statusCode: The status code associated with the `Result`.
  func parseResult<T>(result: Result<T, Error>, statusCode: Int) -> Result<T, Error>
}

extension NetworkTransportPolicy {

  public func resolveHost(for urlRequest: URLRequest, completion: @escaping (Result<String?, Error>) -> Void) {
    completion(.success(nil))
  }

  public func resolveHeaders(for urlRequest: URLRequest, completion: @escaping (Result<[String: String], Error>) -> Void) {
    completion(.success([:]))
  }

  public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
    var urlRequest = urlRequest

    resolveHost(for: urlRequest) { hostResult in
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

        resolveHeaders(for: urlRequest) { headersResult in
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
    default: return .success(())
    }
  }

  public func parseResult<T>(result: Result<T, Error>, statusCode: Int) -> Result<T, Error> {
    switch result {
    case .failure(let error):
      return .failure(error)
    case .success(let data):
      if let error = try? (data as? NetworkErrorConvertible)?.asNetworkError(statusCode: statusCode) {
        return .failure(error)
      }

      switch statusCode {
      case 400..<499:
        return .failure(NetworkError.client(code: statusCode))
      case 500..<599:
        return .failure(NetworkError.server(code: statusCode))
      default:
        return .success(data)
      }
    }
  }
}
