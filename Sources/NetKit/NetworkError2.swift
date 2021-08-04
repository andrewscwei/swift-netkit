// © Sybl

import Foundation

/// An `Error` conforming enum consiting of errors thrown by `NetworkService` operations. By default, none of the errors have an error description. It is up to the application to extend this error to conform to `LocalizedError` and provide its own localized descriptions.
public enum NetworkError2: Error {

  /// A type of network error whose nature is unknown.
  case unknown(code: Int? = nil, cause: Error? = nil)

  /// A type of network error thrown when there is an authorization failure of some sort, i.e. 401 status code.
  case unauthorized(code: Int? = nil, cause: Error? = nil)

  /// A type of network error thrown when there are too many consecutive similar requests within a short time frame.
  case tooManyRequests(code: Int? = nil, cause: Error? = nil)

  /// A type of network error thrown when there is no network.
  case noNetwork(code: Int? = nil, cause: Error? = nil)
  
  /// A type of network error thrown when a request is cancelled.
  case cancelled(code: Int? = nil, cause: Error? = nil)

  /// A type of network error thrown when the network request is timed out.
  case timeout(code: Int? = nil, cause: Error? = nil)

  /// A type of error thrown when failing to encode request parameters (i.e. query strings, body params, URL params, etc.).
  case encoding(code: Int? = nil, cause: Error? = nil)

  /// A type of network error thrown when decoding the response of the request.
  case decoding(code: Int? = nil, cause: Error? = nil)

  /// A type of network error thrown when failing to upload packets to the server.
  case upload(code: Int? = nil, cause: Error? = nil)

  /// A type of network error thrown when failing to download packets from the server.
  case download(code: Int? = nil, cause: Error? = nil)

  /// Generic client-side network error, i.e. 4XX status codes. Use this to encapsulate errors not captured by the predefined enums.
  case client(code: Int? = nil, cause: Error? = nil)

  /// Generic server-side network error, i.e. 5XX status codes. Use this to encapsulate errors not captured by the predefined enums.
  case server(code: Int? = nil, cause: Error? = nil)

  public static let unknown: NetworkError2 = .unknown()
  public static let unauthorized: NetworkError2 = .unauthorized()
  public static let tooManyRequests: NetworkError2 = .tooManyRequests()
  public static let noNetwork: NetworkError2 = .noNetwork()
  public static let cancelled: NetworkError2 = .cancelled()
  public static let timeout: NetworkError2 = .timeout()
  public static let encoding: NetworkError2 = .encoding()
  public static let decoding: NetworkError2 = .decoding()
  public static let upload: NetworkError2 = .upload()
  public static let download: NetworkError2 = .download()
  public static let client: NetworkError2 = .client()
  public static let server: NetworkError2 = .server()
}

extension NetworkError2: CustomNSError {
  public static var errorDomain: String { "network" }

  public  var errorCode: Int {
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

  public  var errorUserInfo: [String: Any] {
    switch self {
    default: return [:]
    }
  }
}
