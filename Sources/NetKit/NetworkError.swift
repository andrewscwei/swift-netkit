// © Sybl

import Foundation

/// An `Error` conforming enum consiting of errors thrown by `NetworkTransport` operations. By
/// default, none of the errors have an error description. It is up to the application to extend
/// this error to conform to `LocalizedError` and provide its own localized descriptions.
public enum NetworkError: Error {

  /// A type of network error whose nature is unknown.
  case unknown(code: Int? = nil, cause: Error? = nil)

  /// A type of network error thrown when there is an authorization failure of some sort, i.e. 401
  /// status code.
  case unauthorized(code: Int? = nil, cause: Error? = nil)

  /// A type of network error thrown when there are too many consecutive same requests within a
  /// short time frame.
  case tooManyRequests(code: Int? = nil, cause: Error? = nil)

  /// A type of network error thrown when there is no network.
  case noNetwork(code: Int? = nil, cause: Error? = nil)

  /// A type of network error thrown when a request is cancelled.
  case cancelled(code: Int? = nil, cause: Error? = nil)

  /// A type of network error thrown when the network request is timed out.
  case timeout(code: Int? = nil, cause: Error? = nil)

  /// A type of error thrown when failing to encode request parameters (i.e. query strings, body
  /// params, URL params, etc.).
  case encoding(code: Int? = nil, cause: Error? = nil)

  /// A type of network error thrown when decoding the response of the request.
  case decoding(code: Int? = nil, cause: Error? = nil)

  /// A type of network error thrown when failing to upload packets to the server.
  case upload(code: Int? = nil, cause: Error? = nil)

  /// A type of network error thrown when failing to download packets from the server.
  case download(code: Int? = nil, cause: Error? = nil)

  /// Generic client-side network error, i.e. 4XX status codes.
  case client(code: Int? = nil, cause: Error? = nil)

  /// Generic server-side network error, i.e. 5XX status codes.
  case server(code: Int? = nil, cause: Error? = nil)

  /// A type of network error whose nature is unknown.
  public static let unknown: NetworkError = .unknown()

/// A type of network error thrown when there is an authorization failure of some sort, i.e. 401
/// status code.
  public static let unauthorized: NetworkError = .unauthorized()

  /// A type of network error thrown when there are too many consecutive same requests within a
  /// short time frame.
  public static let tooManyRequests: NetworkError = .tooManyRequests()

  /// A type of network error thrown when there is no network.
  public static let noNetwork: NetworkError = .noNetwork()

  /// A type of network error thrown when a request is cancelled.
  public static let cancelled: NetworkError = .cancelled()

  /// A type of network error thrown when the network request is timed out.
  public static let timeout: NetworkError = .timeout()

  /// A type of error thrown when failing to encode request parameters (i.e. query strings, body
  /// params, URL params, etc.).
  public static let encoding: NetworkError = .encoding()

  /// A type of network error thrown when decoding the response of the request.
  public static let decoding: NetworkError = .decoding()

  /// A type of network error thrown when failing to upload packets to the server.
  public static let upload: NetworkError = .upload()

  /// A type of network error thrown when failing to download packets from the server.
  public static let download: NetworkError = .download()

  /// Generic client-side network error, i.e. 4XX status codes.
  public static let client: NetworkError = .client()

  /// Generic server-side network error, i.e. 5XX status codes.
  public static let server: NetworkError = .server()
}

extension NetworkError: CustomNSError {

  public static var errorDomain: String { "network" }

  public var errorCode: Int {
    switch self {
    case .unknown(let code, _): return code ?? -1
    case .unauthorized(let code, _): return code ?? -1
    case .tooManyRequests(let code, _): return code ?? -1
    case .noNetwork(let code, _): return code ?? -1
    case .cancelled(let code, _): return code ?? -1
    case .timeout(let code, _): return code ?? -1
    case .encoding(let code, _): return code ?? -1
    case .decoding(let code, _): return code ?? -1
    case .upload(let code, _): return code ?? -1
    case .download(let code, _): return code ?? -1
    case .client(let code, _): return code ?? -1
    case .server(let code, _): return code ?? -1
    }
  }

  public var errorUserInfo: [String: Any] {
    switch self {
    default: return [:]
    }
  }
}
