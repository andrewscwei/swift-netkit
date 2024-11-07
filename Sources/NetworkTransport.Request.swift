import Alamofire
import Foundation

extension NetworkTransport {

  /// Sends a request to a `NetworkEndpoint`, returning decodable data of type
  /// `T` from the response.
  ///
  /// Custom response parsing can be provided by a `NetworkTransportPolicy`. If
  /// `T` conforms to `ErrorConvertible` and the response data can be
  /// constructed as an error, it will be automatically thrown.
  ///
  /// - Parameters:
  ///   - endpoint: The `NetworkEndpoint`.
  ///   - tag: Custom identifier tag, auto-generated if unspecified.
  ///   - replace: Indicates if this request should repalce an existing active
  ///              request with the same tag by cancelling it.
  ///
  /// - Returns: The decoded response data.
  @discardableResult
  public func request<T: Decodable & Sendable>(
    _ endpoint: NetworkEndpoint,
    tag: String? = nil,
    replace: Bool = false
  ) async throws -> T {
    let tag = tag ?? generateTag(from: endpoint)

    _log.debug("<\(tag)> Requesting \(endpoint)...")

    let request = createRequest(endpoint, tag: tag, replace: replace)
    let response = await request.serializingDecodable(T.self).response
    let statusCode = response.response?.statusCode

    defer {
      removeRequestFromQueue(tag: tag)
    }

    do {
      let data = try policy.parseResponse(response)

      _log.debug("<\(tag)> Requesting \(endpoint)... [\(statusCode ?? 0)] OK")
      _log.debug("> data=\(data)")

      return data
    }
    catch {
      if let error = error as? NetworkError, case .cancelled = error {
        _log.debug("<\(tag)> Requesting \(endpoint)... [\(statusCode ?? 0)] CANCEL: \(error)")
      }
      else {
        _log.error("<\(tag)> Requesting \(endpoint)... [\(statusCode ?? 0)] ERR: \(error)")

        if let payload = response.data, let json = try? JSONSerialization.jsonObject(with: payload) {
          _log.error("> payload = \(json)")
        }
      }

      throw error
    }
  }

  /// Sends a request to a `NetworkEndpoint`, ignoring any response data.
  ///
  /// - Parameters:
  ///   - endpoint: The `NetworkEndpoint`.
  ///   - tag: Custom identifier tag, auto-generated if unspecified.
  ///   - replace: Indicates if this request should repalce an existing active
  ///              request with the same tag by cancelling it.
  public func request(
    _ endpoint: NetworkEndpoint,
    tag: String? = nil,
    replace: Bool = false
  ) async throws {
    let tag = tag ?? generateTag(from: endpoint)

    _log.debug("<\(tag)> Requesting \(endpoint)...")

    let request = createRequest(endpoint, tag: tag, replace: replace)
    let response = await request.serializingDecodable(Empty.self).response
    let statusCode = response.response?.statusCode

    defer {
      removeRequestFromQueue(tag: tag)
    }

    do {
      try policy.parseResponse(response)

      _log.debug("<\(tag)> Requesting \(endpoint)... [\(statusCode ?? 0)] OK")
    }
    catch {
      if let error = error as? NetworkError, case .cancelled = error {
        _log.debug("<\(tag)> Requesting \(endpoint)... [\(statusCode ?? 0)] CANCEL: \(error)")
      }
      else {
        _log.error("<\(tag)> Requesting \(endpoint)... [\(statusCode ?? 0)] ERR: \(error)")

        if let payload = response.data, let json = try? JSONSerialization.jsonObject(with: payload) {
          _log.error("> payload = \(json)")
        }
      }

      throw error
    }
  }

  private func createRequest(_ endpoint: NetworkEndpoint, tag: String, replace: Bool) -> DataRequest {
    if !replace, let request = getActiveRequest(tag: tag) as? DataRequest {
      return request
    }
    else {
      removeRequestFromQueue(tag: tag)

      let request = AF.request(
        endpoint,
        method: endpoint.method,
        parameters: getSanitizedParameters(for: endpoint),
        encoding: getParameterEncoder(for: endpoint),
        headers: .init(endpoint.headers),
        interceptor: policy,
        requestModifier: { $0.timeoutInterval = endpoint.timeout }
      )
        .validate { _, _, _ in .success(()) }

      addRequestToQueue(request: request, tag: tag)

      return request
    }
  }

  private func getSanitizedParameters(for endpoint: NetworkEndpoint) -> Parameters? {
    guard let parameters = endpoint.parameters, !parameters.isEmpty else { return nil }

    return parameters
  }

  private func getParameterEncoder(for endpoint: NetworkEndpoint) -> ParameterEncoding {
    switch endpoint.method {
    case .put, .patch, .post: return JSONEncoding.default
    default: return URLEncoding(arrayEncoding: .noBrackets, boolEncoding: .literal)
    }
  }
}
