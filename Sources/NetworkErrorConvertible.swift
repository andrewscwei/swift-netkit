/// A type conforming to the `NetworkErrorConvertible` protocol can construct an
/// `NetworkError` from itself.
public protocol NetworkErrorConvertible {
  
  /// Constructs a `NetworkError`.
  ///
  /// - Parameters:
  ///   - statusCode: The status code.
  ///
  /// - Throws: When there is an error (ironically) constructing the error.
  ///
  /// - Returns: The `NetworkError`.
  func asNetworkError(statusCode: Int?) throws -> NetworkError
}
