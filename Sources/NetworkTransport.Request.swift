import Alamofire
import Foundation

extension NetworkTransport {

  /// Sends a request to a `NetworkEndpoint`, returning data of type `R` from
  /// mapping the decodable response payload of type `T`.
  ///
  /// Custom host, headers and/or status code validation can be provided by a
  /// `NetworkTransportPolicy`. If `T` conforms to `ErrorConvertible` and the
  /// response data can be constructed as an error, it will be automatically
  /// thrown.
  ///
  /// - Parameters:
  ///   - endpoint: The `NetworkEndpoint`.
  ///   - tag: Custom identifier tag, auto-generated if unspecified.
  ///   - replace: Indicates if this request should repalce an existing active
  ///              request with the same tag by cancelling it.
  ///   - map: Closure for mapping decodable response payload `T` to output data
  ///          `R`.
  /// - Returns: The decoded and mapped response data.
  public func request<T: Decodable & Sendable, R: Decodable & Sendable>(
    _ endpoint: NetworkEndpoint,
    tag: String? = nil,
    replace: Bool = false,
    map: @escaping (T) throws -> R
  ) async throws -> R {
    let tag = tag ?? generateTag(from: endpoint)
    let request = createRequest(endpoint, tag: tag, replace: replace)

    _log.debug { "<\(tag)> Requesting \(endpoint)..." }

    defer {
      removeRequestFromQueue(tag: tag)
    }

    let response = await request
      .validate { @Sendable in self.policy.validateDecodable(statusCode: $1.statusCode, data: $2, of: T.self) }
      .serializingDecodable(T.self)
      .response

    let statusCode = response.response?.statusCode

    do {
      let data = try response.result.get()

      _log.debug { "<\(tag)> Requesting \(endpoint)... [\(statusCode ?? 0)] OK" }
      _log.debug { "↘︎ payload=\(data)" }

      return try map(data)
    }
    catch {
      let networkError = NetworkError.from(error)

      if
        let data = Empty.value as? R,
        case .decoding(_, _, let cause) = networkError,
        case .responseSerializationFailed(let reason) = cause as? AFError
      {
        switch reason {
        case .inputDataNilOrZeroLength, .invalidEmptyResponse:
          _log.debug { "<\(tag)> Requesting \"\(endpoint)\"... [\(statusCode ?? 0)] OK" }
          _log.debug { "↘︎ payload=\(data)" }
          
          return data
        default:
          break
        }
      }

      _log.error { "<\(tag)> Requesting \(endpoint)... [\(statusCode ?? 0)] \(NetworkError.isCancelled(networkError) ? "CANCEL" : "ERR"): \(networkError)" }

      if let data = response.data {
        _log.error { "↘︎ payload=\(String(data: data, encoding: .utf8) ?? "<empty>")" }
      }

      throw networkError
    }
  }

  /// Sends a request to a `NetworkEndpoint`, returning decodable data of type
  /// `T` from the response.
  ///
  /// Custom host, headers and/or status code validation can be provided by a
  /// `NetworkTransportPolicy`. If `T` conforms to `ErrorConvertible` and the
  /// response data can be constructed as an error, it will be automatically
  /// thrown.
  ///
  /// - Parameters:
  ///   - endpoint: The `NetworkEndpoint`.
  ///   - tag: Custom identifier tag, auto-generated if unspecified.
  ///   - replace: Indicates if this request should repalce an existing active
  ///              request with the same tag by cancelling it.
  /// - Returns: The decoded response data.
  public func request<T: Decodable & Sendable>(
    _ endpoint: NetworkEndpoint,
    tag: String? = nil,
    replace: Bool = false
  ) async throws -> T {
    return try await request(endpoint, tag: tag, replace: replace) { $0 }
  }

  /// Sends a request to a `NetworkEndpoint`, ignoring any response data.
  ///
  /// Custom host, headers and/or status code validation can be provided by a
  /// `NetworkTransportPolicy`. If `T` conforms to `ErrorConvertible` and the
  /// response data can be constructed as an error, it will be automatically
  /// thrown.
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
    let _: Empty = try await request(endpoint, tag: tag, replace: replace)
  }

  private func createRequest(_ endpoint: NetworkEndpoint, tag: String, replace: Bool) -> DataRequest {
    if !replace, let request = getActiveRequest(tag: tag) as? DataRequest {
      return request
    }

    removeRequestFromQueue(tag: tag, forceCancel: true)

    let request = AF.request(
      endpoint,
      method: endpoint.method,
      parameters: getSanitizedParameters(for: endpoint),
      encoding: getParameterEncoder(for: endpoint),
      headers: HTTPHeaders(endpoint.headers),
      interceptor: policy,
      requestModifier: { $0.timeoutInterval = endpoint.timeout }
    )

    return addRequestToQueue(request, tag: tag)
  }

  private func getSanitizedParameters(for endpoint: NetworkEndpoint) -> Parameters? {
    guard let parameters = endpoint.parameters, !parameters.isEmpty else {
      return nil
    }

    return parameters
  }

  private func getParameterEncoder(for endpoint: NetworkEndpoint) -> ParameterEncoding {
    switch endpoint.method {
    case .put, .patch, .post:
      return JSONEncoding.default
    default:
      return URLEncoding(arrayEncoding: .noBrackets, boolEncoding: .literal)
    }
  }
}
