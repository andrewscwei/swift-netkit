import Alamofire
import Foundation

/// A type provided to `NetworkTransport` to preconfigure and/or intercept its
/// requests.
public protocol NetworkTransportPolicy: RequestInterceptor {
  /// Resolves and returns the host for the specified `URLRequest`.
  ///
  /// - Parameters:
  ///   - urlRequest: The `URLRequest`.
  ///
  /// - Returns: The resolved host or `nil` if unavailable.
  func resolveHost(for urlRequest: URLRequest) async throws -> String?

  /// Resolves and returns the headers for the specified `URLRequest`.
  ///
  /// - Parameters:
  ///   - urlRequest: The `URLRequest`.
  ///
  /// - Returns: The resolved headers.
  func resolveHeaders(for urlRequest: URLRequest) async throws -> [String: String]
}

extension NetworkTransportPolicy {
  public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping @Sendable (Result<URLRequest, Error>) -> Void) {
    Task {
      do {
        var urlRequest = urlRequest
        let host = try await resolveHost(for: urlRequest)

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

        let headers = try await resolveHeaders(for: urlRequest)

        for (key, value) in headers {
          urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        completion(.success(urlRequest))
      }
      catch {
        completion(.failure(error))
      }
    }
  }

  public func resolveHost(for urlRequest: URLRequest) async throws -> String? { nil }

  public func resolveHeaders(for urlRequest: URLRequest) async throws -> [String: String] { [:] }

  func parseResponse(_ response: DataResponse<Empty, some Error>) throws {
    switch response.result {
    case .failure(let error):
      if let error = error as? AFError, case .responseSerializationFailed(let reason) = error, case .inputDataNilOrZeroLength = reason {
        fallthrough
      }
      else {
        throw NetworkError.from(error)
      }
    case .success:
      let statusCode = response.response?.statusCode
      try validateStatusCode(statusCode)
    }
  }

  func parseResponse<T>(_ response: DataResponse<T, some Error>) throws -> T {
    switch response.result {
    case .failure(let error):
      throw NetworkError.from(error)
    case .success(let data):
      let statusCode = response.response?.statusCode
      try validateStatusCode(statusCode)

      if let networkError = try? (data as? NetworkErrorConvertible)?.asNetworkError(statusCode: statusCode) {
        throw networkError
      }

      return data
    }
  }

  func parseResponse(_ response: DownloadResponse<URL, some Error>) throws -> URL {
    switch response.result {
    case .failure(let error):
      throw NetworkError.from(error)
    case .success(let fileURL):
      let statusCode = response.response?.statusCode
      try validateStatusCode(statusCode)

      return fileURL
    }
  }

  func validateStatusCode(_ statusCode: Int?) throws {
    guard let statusCode = statusCode else { throw NetworkError.noResponse }

    switch statusCode {
    case 401:
      throw NetworkError.unauthorized(statusCode: statusCode)
    case 429:
      throw NetworkError.tooManyRequests(statusCode: statusCode)
    case 400..<499:
      throw NetworkError.client(statusCode: statusCode)
    case 500..<599:
      throw NetworkError.server(statusCode: statusCode)
    default:
      break
    }
  }
}
