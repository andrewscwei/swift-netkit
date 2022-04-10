// © GHOZT

import Foundation

/// A type conforming to the `NetworkErrorConvertible` protocol can construct an `NetworkError` from
/// itself.
public protocol NetworkErrorConvertible {

  /// Constructs an `NetworkError`.
  ///
  /// - Parameter statusCode: The status code.
  ///
  /// - Throws: When there is an error (ironically) constructing the error.
  ///
  /// - Returns: The `NetworkError`.
  func asNetworkError(statusCode: Int?) throws -> NetworkError
}
