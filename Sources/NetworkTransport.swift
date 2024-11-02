import Alamofire
import Foundation

/// An object delegated to making JSON network requests.
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
public class NetworkTransport {

  /// Default `NetworkTransportPolicy` to use when one is not provided.
  final class DefaultPolicy: NetworkTransportPolicy {}

  /// Dispatch queue for thread-safe read and write of mutable members.
  let lockQueue: DispatchQueue = .init(label: "NetKit.NetworkTransport", qos: .utility)

  /// The policy of this `NetworkTransport`.
  var policy: NetworkTransportPolicy

  /// Map of active network requests accessible by their tags.
  var requestQueue: [String: Request] = [:]

  /// Creates a new `NetworkTransport` instance using the default
  /// `NetworkTransportPolicy`.
  public convenience init() {
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
    lockQueue.sync { () -> Request? in
      guard let request = requestQueue[tag], !request.isCancelled, !request.isFinished, !request.isSuspended else { return nil }
      return request
    }
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
  @discardableResult func addRequestToQueue(request: Request, tag: String, overwriteExisting: Bool = true) -> Request {
    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) {
      _log.debug("Adding request with tag <\(tag)> to queue... SKIP: A request already exists with that tag, returning the existing request instead")
      return existingRequest
    }

    lockQueue.sync(flags: [.barrier]) {
      requestQueue[tag]?.cancel()
      requestQueue[tag] = request
      _log.debug("Adding request with tag <\(tag)> to queue... OK: Queue = \(requestQueue.keys)")
    }

    return request
  }

  /// Cancels a request and removes it from the queue.
  ///
  /// - Parameters:
  ///   - tag: The tag associated with the request.
  ///
  /// - Returns: The removed request.
  @discardableResult func removeRequestFromQueue(tag: String) -> Request? {
    guard let request = getActiveRequest(tag: tag) else { return nil }
    request.cancel()

    lockQueue.sync(flags: [.barrier]) {
      requestQueue.removeValue(forKey: tag)

      _log.debug("Removing request with tag <\(tag)>... OK: Queue = \(requestQueue.keys)")
    }

    return request
  }

  /// Cancels and clears all existing requests.
  public func clearAllRequests() {
    for (_, request) in requestQueue {
      request.cancel()
    }

    requestQueue = [:]

    _log.debug("Removing all requests from queue... OK: Queue = \(requestQueue.keys)")
  }

  /// Generates a request tag from the given `NetworkEndpoint`.
  ///
  /// - Parameters:
  ///   - endpoint: The `NetworkEndpoint`.
  ///
  /// - Returns: The generated tag.
  func generateTagFromEndpoint(_ endpoint: NetworkEndpoint) -> String {
    return "[\(endpoint.method.rawValue.uppercased())] \(endpoint)"
  }
}
