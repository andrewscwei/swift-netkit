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

  /// Validates the response.
  ///
  /// - Parameters:
  ///   - response: The response.
  func validate(response: HTTPURLResponse) throws

  /// Parses a `DataResponse` and returns its data payload.
  ///
  /// - Parameters:
  ///   - response: The `DataResponse`.
  func parseResponse(_ response: DataResponse<Empty, some Error>) throws

  /// Parses a `DataResponse` and returns its data payload.
  ///
  /// - Parameters:
  ///   - response: The `DataResponse`.
  ///
  /// - Returns: The response data.
  func parseResponse<T>(_ response: DataResponse<T, some Error>) throws -> T
  

  /// Parses a `DownloadResponse` and returns the file URL.
  ///
  /// - Parameter response: The `DownloadResponse`.
  ///
  /// - Returns: The file URL.
  func parseResponse(_ response: DownloadResponse<URL, some Error>) throws -> URL
}

extension NetworkTransportPolicy {
  public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
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

  public func validate(response: HTTPURLResponse) throws {
    let statusCode = response.statusCode

    switch statusCode {
    case 401:
      throw NetworkError.unauthorized(statusCode: statusCode)
    case 429:
      throw NetworkError.tooManyRequests(statusCode: statusCode)
    default:
      break
    }
  }

  public func parseResponse(_ response: DataResponse<Empty, some Error>) throws {
    switch response.result {
    case .failure(let error):
      if let error = error as? AFError, case .responseSerializationFailed(let reason) = error, case .inputDataNilOrZeroLength = reason {
        fallthrough
      }
      else {
        throw NetworkError.from(error)
      }
    case .success:
      guard let statusCode = response.response?.statusCode else { throw NetworkError.noResponse }

      switch statusCode {
      case 400..<499:
        throw NetworkError.client(statusCode: statusCode)
      case 500..<599:
        throw NetworkError.server(statusCode: statusCode)
      default:
        break
      }
    }
  }

  public func parseResponse<T>(_ response: DataResponse<T, some Error>) throws -> T {
    switch response.result {
    case .failure(let error):
      throw NetworkError.from(error)
    case .success(let data):
      guard let statusCode = response.response?.statusCode else { throw NetworkError.noResponse }

      if let networkError = try? (data as? NetworkErrorConvertible)?.asNetworkError(statusCode: statusCode) {
        throw networkError
      }

      switch statusCode {
      case 400..<499:
        throw NetworkError.client(statusCode: statusCode)
      case 500..<599:
        throw NetworkError.server(statusCode: statusCode)
      default:
        return data
      }
    }
  }

  public func parseResponse(_ response: DownloadResponse<URL, some Error>) throws -> URL {
    guard let _ = response.response?.statusCode else { throw NetworkError.noResponse }

    switch response.result {
    case .failure(let error):
      throw NetworkError.from(error)
    case .success(let fileURL):
      return fileURL
    }
  }
}
