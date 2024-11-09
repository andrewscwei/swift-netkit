import Alamofire
import Foundation

/// An actor delegated to making JSON network requests.
///
/// When parsing a response data of type `T`, if `T` conforms to
/// `ErrorConvertible` and an error can be constructed from the data, expect a
/// `Result.failure` in the response handlers with an appropriate `NetworkError`
/// wrapping the constructed error as its `cause`. As such, it is best to handle
/// server provided error messages in the `ErrorConvertible` data type and
/// unwrap the message from the `NetworkError` when a response is received. To
/// simplify this process, it is recommended to use an extension for
/// `NetworkError` specific to the application to automatically extract the
/// error message.
public actor NetworkTransport {
  final class DefaultPolicy: NetworkTransportPolicy {}

  let policy: NetworkTransportPolicy
  var requestQueue: [String: Request] = [:]

  /// Creates a new `NetworkTransport` instance using the default
  /// `NetworkTransportPolicy`.
  public init() {
    self.init(policy: DefaultPolicy())
  }

  /// Creates a new `NetworkTransport` instance.
  ///
  /// - Parameters:
  ///   - policy: The `NetworkTransportPolicy` to use.
  public init(policy: NetworkTransportPolicy) {
    self.policy = policy
  }

  /// Cancels and clears all existing requests.
  public func clearAllRequests() {
    for (_, request) in requestQueue {
      request.cancel()
    }

    requestQueue = [:]
  }

  @discardableResult
  func addRequestToQueue<T: Request>(_ request: T, tag: String) -> T {
    requestQueue[tag] = request

    return request
  }

  @discardableResult
  func removeRequestFromQueue(tag: String, forceCancel: Bool = false) -> Request? {
    guard let request = requestQueue[tag] else { return nil }

    if forceCancel {
      request.cancel()
    }

    requestQueue.removeValue(forKey: tag)

    return request
  }

  func getActiveRequest(tag: String) -> Request? {
    guard let request = requestQueue[tag], !request.isCancelled, !request.isFinished, !request.isSuspended else {
      return nil
    }

    return request
  }

  func generateTag(from aString: String) -> String {
    var hash: UInt32 = 5381

    for char in aString.utf8 {
      hash = ((hash << 5) &+ hash) &+ UInt32(char)
    }

    return String(format: "%08x", hash)
  }

  func generateTag(from endpoint: NetworkEndpoint) -> String { generateTag(from: endpoint.description) }
}
