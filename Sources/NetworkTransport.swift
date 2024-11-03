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

  /// Default `NetworkTransportPolicy` to use when one is not provided.
  final class DefaultPolicy: NetworkTransportPolicy {}

  /// The policy of this `NetworkTransport`.
  let policy: NetworkTransportPolicy

  /// Map of active network requests accessible by their tags.
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

  /// Gets the active request by its tag name. An active request refers to an
  /// existing request that is not cancelled, finished or suspended.
  ///
  /// - Parameters:
  ///   - tag: The tag associated with the request.
  ///
  /// - Returns: The active request if there is a match.
  public func getActiveRequest(tag: String) -> Request? {
    guard let request = requestQueue[tag], !request.isCancelled, !request.isFinished, !request.isSuspended else { return nil }

    return request
  }

  /// Adds a request to the queue.
  ///
  /// - Parameters:
  ///   - request: The request to add.
  ///   - tag: The tag to associate with the request.
  ///   - overwriteExisting: Specifies if the new request should overwrite an
  ///                        existing one with the same tag. The existing
  ///                        request will be subsequently cancelled.
  ///
  /// - Returns: Either the request that was added, or the existing request with
  ///            the specified tag name if `overwriteExisting` is `false`.
  @discardableResult
  func addRequestToQueue(request: Request, tag: String, overwriteExisting: Bool = true) -> Request {
    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) {
      _log.debug("Adding request with tag <\(tag)> to queue... SKIP: A request already exists with that tag, returning the existing request instead")
      return existingRequest
    }

    requestQueue[tag]?.cancel()
    requestQueue[tag] = request

    _log.debug("Enqueuing request <\(tag)>... OK: Queue = \(requestQueue.keys)")

    return request
  }

  /// Cancels a request and removes it from the queue.
  ///
  /// - Parameters:
  ///   - tag: The tag associated with the request.
  ///
  /// - Returns: The removed request.
  @discardableResult
  func removeRequestFromQueue(tag: String) -> Request? {
    guard let request = getActiveRequest(tag: tag) else { return nil }

    request.cancel()
    requestQueue.removeValue(forKey: tag)

    _log.debug("Dequeuing request <\(tag)>... OK: Queue = \(requestQueue.keys)")

    return request
  }

  /// Cancels and clears all existing requests.
  public func clearAllRequests() {
    for (_, request) in requestQueue {
      request.cancel()
    }

    requestQueue = [:]

    _log.debug("Dequeuing all requests... OK: Queue = \(requestQueue.keys)")
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
