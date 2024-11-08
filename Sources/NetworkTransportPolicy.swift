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

  /// Validates the response status code prior to returning the response.
  ///
  /// The default implementation of this method alreadyhandles common error
  /// codes. By implementing this method you will be responsible for handling
  /// all status codes.
  ///
  /// - Parameters:
  ///   - statusCode: The status code.
  /// - Throws: If the status code should be treated as an error.
  func validate(statusCode: Int) throws
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

  public func validate(statusCode: Int) throws {
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

  func validateStatusCode(_ statusCode: Int) -> Result<Void, any Error> {
    do {
      try validate(statusCode: statusCode)

      return .success(())
    }
    catch {
      return .failure(NetworkError.from(error))
    }
  }

  func validateDecodable<T: Decodable>(statusCode: Int, data: Data?, of type: T.Type) -> Result<Void, any Error> {
    switch validateStatusCode(statusCode) {
    case .success:
      return .success(())
    case .failure(let error):
      guard let data = data else {
        return .failure(error)
      }

      if let convertibleType = T.self as? (Decodable & NetworkErrorConvertible).Type {
        do {
          let decoded = try JSONDecoder().decode(convertibleType, from: data)
          let networkError = try decoded.asNetworkError(statusCode: statusCode)

          return .failure(networkError)
        }
        catch {
          return .failure(NetworkError.decoding(statusCode: statusCode, cause: error))
        }
      }
      else {
        do {
          _ = try JSONDecoder().decode(T.self, from: data)

          return .failure(error)
        }
        catch {
          return .failure(NetworkError.decoding(statusCode: statusCode, cause: error))
        }
      }
    }
  }
}
