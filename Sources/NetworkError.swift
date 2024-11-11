import Alamofire
import Foundation

/// An `Error` conforming enum representing errors from `NetworkTransport`
/// operations. By default, errors lack descriptions. Applications should
/// extend this enum to conform to `LocalizedError` for localized descriptions.
public enum NetworkError: Error {

  /// A type of network error thrown when a request is cancelled.
  case cancelled(code: String? = nil, cause: Error? = nil)

  /// Generic client-side network error, i.e. 4XX status codes.
  case client(statusCode: Int? = nil, code: String? = nil, cause: Error? = nil)

  /// A type of network error thrown when decoding the response of the request.
  case decoding(statusCode: Int? = nil, code: String? = nil, cause: Error? = nil)

  /// A type of network error thrown when failing to download packets from the
  /// server.
  case download(statusCode: Int? = nil, code: String? = nil, cause: Error? = nil)

  /// A type of error thrown when failing to encode request parameters (i.e.
  /// query strings, body params, URL params, etc.).
  case encoding(statusCode: Int? = nil, code: String? = nil, cause: Error? = nil)

  /// A type of network error thrown when there is no network.
  case noNetwork(code: String? = nil, cause: Error? = nil)

  /// A type of network error thrown when there is no response.
  case noResponse(code: String? = nil, cause: Error? = nil)

  /// Generic server-side network error, i.e. 5XX status codes.
  case server(statusCode: Int? = nil, code: String? = nil, cause: Error? = nil)

  /// A type of network error thrown when the network request is timed out.
  case timeout(code: String? = nil, cause: Error? = nil)

  /// A type of network error thrown when there are too many consecutive same
  /// requests within a short time frame.
  case tooManyRequests(statusCode: Int? = nil, code: String? = nil, cause: Error? = nil)

  /// A type of network error thrown when there is an authorization failure of
  /// some sort, i.e. 401 status code.
  case unauthorized(statusCode: Int? = nil, code: String? = nil, cause: Error? = nil)

  /// A type of network error whose nature is unknown or is unhandled by
  /// `NetworkTransport`.
  case unknown(statusCode: Int? = nil, code: String? = nil, cause: Error? = nil)

  /// A type of network error thrown when failing to upload packets to the
  /// server.
  case upload(statusCode: Int? = nil, code: String? = nil, cause: Error? = nil)

  /// A type of network error thrown when a request is cancelled.
  public static let cancelled: NetworkError = .cancelled()

  /// Generic client-side network error, i.e. 4XX status codes.
  public static let client: NetworkError = .client()

  /// A type of network error thrown when decoding the response of the request.
  public static let decoding: NetworkError = .decoding()

  /// A type of network error thrown when failing to download packets from the
  /// server.
  public static let download: NetworkError = .download()

  /// A type of error thrown when failing to encode request parameters (i.e.
  /// query strings, body params, URL params, etc.).
  public static let encoding: NetworkError = .encoding()

  /// A type of network error thrown when there is no network.
  public static let noNetwork: NetworkError = .noNetwork()

  /// A type of network error thrown when there is no response.
  public static let noResponse: NetworkError = .noResponse()

  /// Generic server-side network error, i.e. 5XX status codes.
  public static let server: NetworkError = .server()

  /// A type of network error thrown when the network request is timed out.
  public static let timeout: NetworkError = .timeout()

  /// A type of network error thrown when there are too many consecutive same
  /// requests within a short time frame.
  public static let tooManyRequests: NetworkError = .tooManyRequests()

  /// A type of network error thrown when there is an authorization failure of
  /// some sort, i.e. 401 status code.
  public static let unauthorized: NetworkError = .unauthorized()

  /// A type of network error whose nature is unknown or is unhandled by
  /// `NetworkTransport`.
  public static let unknown: NetworkError = .unknown()

  /// A type of network error thrown when failing to upload packets to the
  /// server.
  public static let upload: NetworkError = .upload()

  /// Clones the `NetworkError` with optional modified associated values.
  ///
  /// - Parameters:
  ///   - newStatusCode: New status code.
  ///   - newCode: New code.
  ///   - newCause: New cause.
  /// - Returns: The cloned `NetworkError`.
  func clone(statusCode newStatusCode: Int? = nil, code newCode: String? = nil, cause newCause: Error? = nil) -> Self {
    switch self {
    case let .cancelled(code, cause):
      return .cancelled(code: newCode ?? code, cause: newCause ?? cause)
    case let .client(statusCode, code, cause):
      return .client(statusCode: newStatusCode ?? statusCode, code: newCode ?? code, cause: newCause ?? cause)
    case let .decoding(statusCode, code, cause):
      return .decoding(statusCode: newStatusCode ?? statusCode, code: newCode ?? code, cause: newCause ?? cause)
    case let .download(statusCode, code, cause):
      return .download(statusCode: newStatusCode ?? statusCode, code: newCode ?? code, cause: newCause ?? cause)
    case let .encoding(statusCode, code, cause):
      return .encoding(statusCode: newStatusCode ?? statusCode, code: newCode ?? code, cause: newCause ?? cause)
    case let .noNetwork(code, cause):
      return .noNetwork(code: newCode ?? code, cause: newCause ?? cause)
    case let .noResponse(code, cause):
      return .noResponse(code: newCode ?? code, cause: newCause ?? cause)
    case let .server(statusCode, code, cause):
      return .server(statusCode: newStatusCode ?? statusCode, code: newCode ?? code, cause: newCause ?? cause)
    case let .timeout(code, cause):
      return .timeout(code: newCode ?? code, cause: newCause ?? cause)
    case let .tooManyRequests(statusCode, code, cause):
      return .tooManyRequests(statusCode: newStatusCode ?? statusCode, code: newCode ?? code, cause: newCause ?? cause)
    case let .unauthorized(statusCode, code, cause):
      return .unauthorized(statusCode: newStatusCode ?? statusCode, code: newCode ?? code, cause: newCause ?? cause)
    case let .unknown(statusCode, code, cause):
      return .unknown(statusCode: newStatusCode ?? statusCode, code: newCode ?? code, cause: newCause ?? cause)
    case let .upload(statusCode, code, cause):
      return .upload(statusCode: newStatusCode ?? statusCode, code: newCode ?? code, cause: newCause ?? cause)
    }
  }
}

extension NetworkError {
  public var statusCode: Int? {
    switch self {
    case .cancelled(_, _): return nil
    case .client(let statusCode, _, _): return statusCode
    case .decoding(let statusCode, _, _): return statusCode
    case .download(let statusCode, _, _): return statusCode
    case .encoding(let statusCode, _, _): return statusCode
    case .noNetwork(_, _): return nil
    case .noResponse(_, _): return nil
    case .server(let statusCode, _, _): return statusCode
    case .timeout(_, _): return nil
    case .tooManyRequests(let statusCode, _, _): return statusCode
    case .unauthorized(let statusCode, _, _): return statusCode
    case .unknown(let statusCode, _, _): return statusCode
    case .upload(let statusCode, _, _): return statusCode
    }
  }

  public var code: String? {
    switch self {
    case .cancelled(let code, _): return code
    case .client(_, let code, _): return code
    case .decoding(_, let code, _): return code
    case .download(_, let code, _): return code
    case .encoding(_, let code, _): return code
    case .noNetwork(let code, _): return code
    case .noResponse(let code, _): return code
    case .server(_, let code, _): return code
    case .timeout(let code, _): return code
    case .tooManyRequests(_, let code, _): return code
    case .unauthorized(_, let code, _): return code
    case .unknown(_, let code, _): return code
    case .upload(_, let code, _): return code
    }
  }

  public var cause: Error? {
    switch self {
    case .cancelled(_, let cause): return cause
    case .client(_, _, let cause): return cause
    case .decoding(_, _, let cause): return cause
    case .download(_, _, let cause): return cause
    case .encoding(_, _, let cause): return cause
    case .noNetwork(_, let cause): return cause
    case .noResponse(_, let cause): return cause
    case .server(_, _, let cause): return cause
    case .timeout(_, let cause): return cause
    case .tooManyRequests(_, _, let cause): return cause
    case .unauthorized(_, _, let cause): return cause
    case .unknown(_, _, let cause): return cause
    case .upload(_, _, let cause): return cause
    }
  }
}

extension NetworkError {
  /// Creates a `NetworkError` from a `URLError`.
  ///
  /// - Parameters:
  ///   - urlError: The `URLError`.
  /// - Returns: The `NetworkError`.
  public static func from(_ urlError: URLError) -> NetworkError {
    let errorCode = "\(urlError.errorCode)"

    switch urlError.code {
    case .cancelled:
      return .cancelled(code: errorCode, cause: urlError)
    case .notConnectedToInternet:
      return .noNetwork(code: errorCode, cause: urlError)
    case .timedOut:
      return .timeout(code: errorCode, cause: urlError)
    default:
      return .unknown(code: errorCode, cause: urlError)
    }
  }

  /// Creates a `NetworkError` from an `AFError`.
  ///
  /// - Parameters:
  ///   - afError: The `AFError`.
  /// - Returns: The `NetworkError`.
  public static func from(_ afError: AFError) -> NetworkError {
    let statusCode = afError.responseCode

    switch afError {
    case .responseValidationFailed(let reason):
      switch reason {
      case .customValidationFailed(let cause):
        return from(cause)
      default:
        return .client(statusCode: statusCode, cause: afError)
      }
    case .explicitlyCancelled:
      return .cancelled(cause: afError)
    case .sessionTaskFailed(let error):
      return from(error)
    case .responseSerializationFailed:
      return .decoding(statusCode: statusCode, cause: afError)
    default:
      return .unknown(statusCode: statusCode, cause: afError)
    }
  }

  /// Creates a `NetworkError` from any `Error`.
  ///
  /// - Parameters:
  ///   - error: The `Error`.
  /// - Returns: The `NetworkError`.
  public static func from(_ error: any Error) -> NetworkError {
    if let networkError = error as? NetworkError {
      return networkError
    }
    else if let afError = error as? AFError {
      return from(afError)
    }
    else if let urlError = error as? URLError {
      return from(urlError)
    }
    else {
      return .unknown(cause: error)
    }
  }

  /// Checks if the error is `NetworkError.cancelled`.
  ///
  /// - Parameter error: The error.
  /// - Returns: `true` if the error is `NetworkError.cancelled`, `false`
  ///            otherwise.
  public static func isCancelled(_ error: any Error) -> Bool {
    if let error = error as? NetworkError, case .cancelled = error {
      return true
    }
    else {
      return false
    }
  }

  /// Checks if the error is `NetworkError.timeout`.
  ///
  /// - Parameter error: The error.
  /// - Returns: `true` if the error is `NetworkError.timeout`, `false`
  ///            otherwise.
  public static func isTimedOut(_ error: any Error) -> Bool {
    if let error = error as? NetworkError, case .timeout = error {
      return true
    }
    else {
      return false
    }
  }

  /// Checks if the error is `NetworkError.noNetwork`.
  ///
  /// - Parameter error: The error.
  /// - Returns: `true` if the error is `NetworkError.noNetwork`, `false`
  ///            otherwise.
  public static func isNoNetwork(_ error: any Error) -> Bool {
    if let error = error as? NetworkError, case .noNetwork = error {
      return true
    }
    else {
      return false
    }
  }

  /// Checks if the error is `NetworkError.unauthorized`.
  ///
  /// - Parameter error: The error.
  /// - Returns: `true` if the error is `NetworkError.unauthorized`, `false`
  ///            otherwise.
  public static func isUnauthorized(_ error: any Error) -> Bool {
    if let error = error as? NetworkError, case .unauthorized = error {
      return true
    }
    else {
      return false
    }
  }
}
