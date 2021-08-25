// © Sybl

import Alamofire
import BaseKit
import Foundation

extension NetworkTransport {

  /// Sends an async request to the `NetworkEndpoint` provided and parses the response as a `Result`
  /// with a success value of decodable type `T`.
  ///
  /// - Parameters:
  ///   - endpoint: The `NetworkEndpoint`.
  ///   - queue: The dispatch queue used for placing the request.
  ///   - tag: Custom tag for identifying this request. One will be generated automatically if
  ///          unspecified.
  ///   - overwriteExisting: Indicates if this request should overwrite an existing request with the
  ///                        same tag. If so, the existing request will be cancelled and this new
  ///                        request will be placed. If `false` and an existing request is active, a
  ///                        new request will not be placed and the existing active request will be
  ///                        returned immediately instead.
  ///   - completion: Handler invoked when the request completes and a response is received. This
  ///                 handler transforms the raw response into a `Result` with codable type `T` as
  ///                 its success value and a `NetworkError` as its failure value. More fine-grained
  ///                 parsing using the response status code is controlled by the active
  ///                 `NetworkTransportPolicy`, via its member `parseResponse(_:statusCode:)`.
  ///
  /// - Returns: The `Request` object.
  @discardableResult public func request<T: Decodable>(
    _ endpoint: NetworkEndpoint,
    queue: DispatchQueue = .global(qos: .utility),
    tag: String? = nil,
    overwriteExisting: Bool = true,
    completion: @escaping (Result<T, Error>) -> Void = { _ in }
  ) -> Request {
    let tag = tag ?? generateTagFromEndpoint(endpoint)

    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) { return existingRequest }

    removeRequestFromQueue(tag: tag)

    log(.debug, isEnabled: debugMode) { "Sending \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"..." }

    let request = AF.request(
      endpoint,
      method: endpoint.method,
      parameters: getSanitizedParameters(for: endpoint),
      encoding: getParameterEncoder(for: endpoint),
      headers: .init(endpoint.headers),
      interceptor: policy,
      requestModifier: { urlRequest in
        urlRequest.timeoutInterval = endpoint.timeout
      })
      .validate({ urlRequest, response, data in self.policy.validate(response: response) })
      .responseDecodable(of: T.self, queue: queue) { [weak self] response in
        guard let weakSelf = self else { return }

        switch response.result {
        case .failure(let error):
          let networkError = NetworkError.from(error)
          log(.error, isEnabled: weakSelf.debugMode) { "Sending \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"... ERR: [\(response.response?.statusCode ?? -1)] \(networkError)" }
          completion(.failure(networkError))
        case .success(let data):
          log(.debug, isEnabled: weakSelf.debugMode) { "Sending \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"... OK: [\(response.response?.statusCode ?? -1)] \(data)" }
          completion(.success(data))
        }
    }

    return addRequestToQueue(request: request, tag: tag)
  }

  /// Sends an async request to the `NetworkEndpoint` provided and parses the response as a `Result`
  /// with a success value of a JSON object.
  ///
  /// - Parameters:
  ///   - endpoint: The `NetworkEndpoint`.
  ///   - queue: The dispatch queue used for placing the request.
  ///   - tag: Custom tag for identifying this request. One will be generated automatically if
  ///          unspecified.
  ///   - overwriteExisting: Indicates if this request should overwrite an existing request with the
  ///                        same tag. If so, the existing request will be cancelled and this new
  ///                        request will be placed. If `false` and an existing request is active, a
  ///                        new request will not be placed and the existing active request will be
  ///                        returned immediately instead.
  ///   - completion: Handler invoked when the request completes and a response is received. This
  ///                 handler transforms the raw response into a `Result` with a JSON decodable
  ///                 object as its success value and a `NetworkError` as its failure value. More
  ///                 fine-grained parsing using the response status code is controlled by the
  ///                 active `NetworkTransportPolicy`, via its member
  ///                 `parseResponse(_:statusCode:)`.
  ///
  /// - Returns: The `Request` object.
  @discardableResult public func request(
    _ endpoint: NetworkEndpoint,
    queue: DispatchQueue = .global(qos: .utility),
    tag: String? = nil,
    overwriteExisting: Bool = true,
    completion: @escaping (Result<Any, Error>) -> Void = { _ in }
  ) -> Request {
    let tag = tag ?? generateTagFromEndpoint(endpoint)

    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) { return existingRequest }

    removeRequestFromQueue(tag: tag)

    log(.debug, isEnabled: debugMode) { "Sending \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"..." }

    let request = AF.request(
      endpoint,
      method: endpoint.method,
      parameters: getSanitizedParameters(for: endpoint),
      encoding: getParameterEncoder(for: endpoint),
      headers: .init(endpoint.headers),
      interceptor: policy,
      requestModifier: { urlRequest in
        urlRequest.timeoutInterval = endpoint.timeout
      })
      .validate({ urlRequest, response, data in self.policy.validate(response: response) })
      .responseJSON(queue: queue) { [weak self] response in
        guard let weakSelf = self else { return }

        switch response.result {
        case .failure(let error):
          let networkError = NetworkError.from(error)
          log(.error, isEnabled: weakSelf.debugMode) { "Sending \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"... ERR: [\(response.response?.statusCode ?? -1)] \(networkError)" }
          completion(.failure(networkError))
        case .success(let data):
          log(.debug, isEnabled: weakSelf.debugMode) { "Sending \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"... OK: [\(response.response?.statusCode ?? -1)] \(data)" }
          completion(.success(data))
        }
    }

    return addRequestToQueue(request: request, tag: tag)
  }

  /// Sends an async request to the `NetworkEndpoint` provided and parses the response as a `Result`
  /// with no success value (i.e. when the payload is discardable or when the status code is
  /// expected to be `204`).
  ///
  /// - Parameters:
  ///   - endpoint: The `NetworkEndpoint`.
  ///   - queue: The dispatch queue used for placing the request.
  ///   - tag: Custom tag for identifying this request. One will be generated automatically if
  ///          unspecified.
  ///   - overwriteExisting: Indicates if this request should overwrite an existing request with the
  ///                        same tag. If so, the existing request will be cancelled and this new
  ///                        request will be placed. If `false` and an existing request is active, a
  ///                        new request will not be placed and the existing active request will be
  ///                        returned immediately instead.
  ///   - completion: Handler invoked when the request completes and a response is received. This
  ///                 handler transforms the raw response into a `Result` with void as its success
  ///                 value and a `NetworkError` as its failure value. More fine-grained parsing
  ///                 using the response status code is controlled by the active
  ///                 `NetworkTransportPolicy`, via its member `parseResponse(_:statusCode:)`.
  ///
  /// - Returns: The `Request` object.
  @discardableResult public func request(
    _ endpoint: NetworkEndpoint,
    queue: DispatchQueue = .global(qos: .utility),
    tag: String? = nil,
    overwriteExisting: Bool = true,
    completion: @escaping (Result<Void, Error>) -> Void = { _ in }
  ) -> Request {
    let tag = tag ?? generateTagFromEndpoint(endpoint)

    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) { return existingRequest }

    removeRequestFromQueue(tag: tag)

    log(.debug, isEnabled: debugMode) { "Sending \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"..." }

    let request = AF.request(
      endpoint,
      method: endpoint.method,
      parameters: getSanitizedParameters(for: endpoint),
      encoding: getParameterEncoder(for: endpoint),
      headers: .init(endpoint.headers),
      interceptor: policy,
      requestModifier: { urlRequest in
        urlRequest.timeoutInterval = endpoint.timeout
      })
      .validate({ urlRequest, response, data in self.policy.validate(response: response) })
      .response(queue: queue) { [weak self] response in
        guard let weakSelf = self else { return }

        switch response.result {
        case .failure(let error):
          let networkError = NetworkError.from(error)
          log(.error, isEnabled: weakSelf.debugMode) { "Sending \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"... ERR: [\(response.response?.statusCode ?? -1)] \(networkError)" }
          completion(.failure(networkError))
        case .success:
          log(.debug, isEnabled: weakSelf.debugMode) { "Sending \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"... OK: [\(response.response?.statusCode ?? -1)]" }
          completion(.success)
        }
      }

    return addRequestToQueue(request: request, tag: tag)
  }

  /// Returns the sanitized `Parameters` of a `NetworkEndpoint`.
  ///
  /// - Parameter endpoint: The `NetworkEntpoint`.
  ///
  /// - Returns: The `Parameters`.
  private func getSanitizedParameters(for endpoint: NetworkEndpoint) -> Parameters? {
    guard let parameters = endpoint.parameters, !parameters.isEmpty else { return nil }
    return parameters
  }

  /// Returns the `ParameterEncoder` based on the endpoint request method.
  ///
  /// - Parameter endpoint: The `NetworkEndpoint`.
  ///
  /// - Returns: The `ParameterEncoder`.
  private func getParameterEncoder(for endpoint: NetworkEndpoint) -> ParameterEncoding {
    switch endpoint.method {
    case .put, .patch, .post: return JSONEncoding.default
    default: return URLEncoding(arrayEncoding: .noBrackets, boolEncoding: .literal)
    }
  }
}
