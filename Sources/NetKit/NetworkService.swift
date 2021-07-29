// © Sybl

import Alamofire
import BaseKit
import Foundation

public  class NetworkService {

  /// Default `NetworkServicePolicy` to use if one is not provided.
  public struct DefaultPolicy: NetworkServicePolicy {
    public init() {}
  }

  /// The policy of this `NetworkService`.
  private var policy: NetworkServicePolicy

  /// Map of active network requests accessible by their tags.
  private var requestQueue: [String: Request] = [:]

  public init(policy: NetworkServicePolicy = DefaultPolicy()) {
    self.policy = policy
  }

  /// Gets the active request by its tag name. An active request refers to an existing request that is not cancelled, finished or suspended.
  ///
  /// - Parameter tag: The tag associated with the request.
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
  ///   - overwriteExisting: Specifies if the new request should overwrite an existing one with the same tag. The existing request will subsequently be cancelled.
  ///
  /// - Returns: Either the request that was added, or the existing request with the specified tag name if `overwriteExisting` is `false`.
  @discardableResult private func addRequestToQueue(request: Request, tag: String, overwriteExisting: Bool = true) -> Request {
    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) { return existingRequest }
    requestQueue[tag]?.cancel()
    requestQueue[tag] = request
    return request
  }

  /// Removes a request from the queue and cancels it.
  ///
  /// - Parameter tag: The tag associated with the request.
  ///
  /// - Returns: The removed request.
  @discardableResult private func removeRequestFromQueue(tag: String) -> Request? {
    let request = getActiveRequest(tag: tag)
    request?.cancel()
    requestQueue.removeValue(forKey: tag)
    return request
  }

  /// Sends an async request based on the `URLRequestConvertible` provided and parses the response as a `Result` with value of codable type `T`.
  ///
  /// - Parameters:
  ///   - urlRequest: The `URLRequestConvertible`.
  ///   - queue: The dispatch queue used for placing the request.
  ///   - tag: Tag for identifying this request—if unspecified, a random UUID will be used.
  ///   - overwriteExisting: Indicates if this request should overwrite an existing request with the same tag. If so, the existing request will be cancelled and this new request will be placed. If `false` and an existing request is active, a new request will not be placed and the existing active request will be returned immediately instead.
  ///   - responseHandler: Handler invoked when the request completes and a response is received. This handler transforms the raw response into a `Result` with codable type `T` as its success value and a `NetworkError2` as its failure value. More fine-grained parsing using the response status code is controlled by the active `NetworkTransportPolicy`, via the member `parseResponse(_:statusCode:)`.
  ///
  /// - Returns: The `Request` object.
  @discardableResult public func request<T: Codable>(_ urlRequest: URLRequestConvertible, queue: DispatchQueue = .global(qos: .utility), tag: String = UUID().uuidString, overwriteExisting: Bool = true, responseHandler: @escaping (Result<T, NetworkError2>) -> Void = { _ in }) -> Request {
    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) { return existingRequest }

    removeRequestFromQueue(tag: tag)

    log(.debug) { "Sending request to endpoint \"\(urlRequest)\"..." }

    let request = AF.request(urlRequest, interceptor: policy).response(queue: queue) { [weak self] response in
      guard let weakSelf = self else { return responseHandler(.failure(NetworkError2.unknown)) }

      let result: Result<T, NetworkError2> = weakSelf.parseResponse(response)
      log(.debug) { "Sending request to endpoint \"\(urlRequest)\"... OK: \(result)" }
      responseHandler(result)
    }

    return addRequestToQueue(request: request, tag: tag)
  }

  /// Sends an async request based on the `URLRequestConvertible` provided and parses the response as a `Result` with JSON object of type `Any`.
  ///
  /// - Parameters:
  ///   - urlRequest: The `URLRequestConvertible`.
  ///   - queue: The dispatch queue used for placing the request.
  ///   - tag: Tag for identifying this request—if unspecified, a random UUID will be used.
  ///   - overwriteExisting: Indicates if this request should overwrite an existing request with the same tag. If so, the existing request will be cancelled and this new request will be placed. If `false` and an existing request is active, a new request will not be placed and the existing active request will be returned immediately instead.
  ///   - responseHandler: Handler invoked when the request completes and a response is received. This handler transforms the raw response into a `Result` with JSON object type `Any` as its success value and a `NetworkError2` as its failure value. More fine-grained parsing using the response status code is controlled by the active `NetworkTransportPolicy`, via the member `parseResponse(_:statusCode:)`.
  ///
  /// - Returns: The `Request` object.
  @discardableResult public func request(_ urlRequest: URLRequestConvertible, queue: DispatchQueue = .global(qos: .utility), tag: String = UUID().uuidString, overwriteExisting: Bool = true, responseHandler: @escaping (Result<Any, NetworkError2>) -> Void = { _ in }) -> Request {
    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) { return existingRequest }

    removeRequestFromQueue(tag: tag)

    log(.debug) { "Sending request to endpoint \"\(urlRequest)\"..." }

    let request = AF.request(urlRequest, interceptor: policy).response(queue: queue) { [weak self] response in
      guard let weakSelf = self else { return responseHandler(.failure(NetworkError2.unknown)) }

      let result: Result<Any, NetworkError2> = weakSelf.parseResponse(response)
      log(.debug) { "Sending request to endpoint \"\(urlRequest)\"... OK: \(result)" }
      responseHandler(result)
    }

    return addRequestToQueue(request: request, tag: tag)
  }

  /// Sends an async request based on the `URLRequestConvertible` provided and parses the response as a `Result` with no value (i.e. when the payload is unimportant or when the status code is expected to be `204`).
  ///
  /// - Parameters:
  ///   - urlRequest: The `URLRequestConvertible`.
  ///   - queue: The dispatch queue used for placing the request.
  ///   - tag: Tag for identifying this request—if unspecified, a random UUID will be used.
  ///   - overwriteExisting: Indicates if this request should overwrite an existing request with the same tag. If so, the existing request will be cancelled and this new request will be placed. If `false` and an existing request is active, a new request will not be placed and the existing active request will be returned immediately instead.
  ///   - responseHandler: Handler invoked when the request completes and a response is received. This handler transforms the raw response into a `Result` with a void success value and a `NetworkError2` as its failure value. More fine-grained parsing using the response status code is controlled by the active `NetworkTransportPolicy`, via the member `parseResponse(_:statusCode:)`.
  ///
  /// - Returns: The `Request` object.
  @discardableResult public func request(_ urlRequest: URLRequestConvertible, queue: DispatchQueue = .global(qos: .utility), tag: String = UUID().uuidString, overwriteExisting: Bool = true, responseHandler: @escaping (Result<Void, NetworkError2>) -> Void = { _ in }) -> Request {
    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) { return existingRequest }

    removeRequestFromQueue(tag: tag)

    log(.debug) { "Sending request to endpoint \"\(urlRequest)\"..." }

    let request = AF.request(urlRequest, interceptor: policy).response(queue: queue) { [weak self] response in
      guard let weakSelf = self else { return responseHandler(.failure(NetworkError2.unknown)) }

      let result: Result<Void, NetworkError2> = weakSelf.parseResponse(response)
      log(.debug) { "Sending request to endpoint \"\(urlRequest)\"... OK: \(result)" }
      responseHandler(result)
    }

    return addRequestToQueue(request: request, tag: tag)
  }

  /// Parses the request response into a `Result` when the response data type is `Any`, where an attempt to serialize it into a JSON object will occur.
  ///
  /// - Parameter response: The request response.
  ///
  /// - Returns: The `Result`.
  private func parseResponse(_ response: AFDataResponse<Data?>) -> Result<Any, NetworkError2> {
    if let error = parseResponseError(response) {
      return .failure(error)
    }
    else if let statusCode = response.response?.statusCode {
      do {
        let decodedData: Any = try parseResponseData(response)
        return policy.parseResponse(decodedData, statusCode: statusCode)
      }
      catch {
        if let error = error as? NetworkError2 {
          return .failure(error)
        }
        else {
          return .failure(.decoding(code: statusCode, cause: error))
        }
      }
    }
    else {
      return .failure(.unknown)
    }
  }

  /// Parses the request response into a `Result` when the response data type is `Void`, as in there is no response data (i.e. a `204` status).
  ///
  /// - Parameter response: The request response.
  ///
  /// - Returns: The `Result`.
  private func parseResponse(_ response: AFDataResponse<Data?>) -> Result<Void, NetworkError2> {
    if let error = parseResponseError(response) {
      return .failure(error)
    }
    else if let statusCode = response.response?.statusCode {
      return policy.parseResponse((), statusCode: statusCode)
    }
    else {
      return .failure(.unknown)
    }
  }

  /// Parses the request repsonse into a `Result` when the response data type is `Codable`.
  ///
  /// - Parameter response: The request response.
  ///
  /// - Returns: The `Result`.
  private func parseResponse<T: Codable>(_ response: AFDataResponse<Data?>) -> Result<T, NetworkError2> {
    if let error = parseResponseError(response) {
      return .failure(error)
    }
    else if let statusCode = response.response?.statusCode {
      do {
        let decodedData: T = try parseResponseData(response)
        return policy.parseResponse(decodedData, statusCode: statusCode)
      }
      catch {
        if let error = error as? NetworkError2 {
          return .failure(error)
        }
        else {
          return .failure(.decoding(code: statusCode, cause: error))
        }
      }
    }
    else {
      return .failure(.unknown)
    }
  }

  /// Transforms the error inside a request response to a `NetworkError2`. If there is no error in the response, `nil` is returned.
  ///
  /// - Parameter response: The request response.
  ///
  /// - Returns: The `NetworkError`, if any.
  private func parseResponseError(_ response: AFDataResponse<Data?>) -> NetworkError2? {
    guard let error = response.error else { return nil }

    let statusCode = response.response?.statusCode

    switch (error as NSError).code {
    case URLError.Code.cancelled.rawValue: return .cancelled(code: statusCode, cause: error)
    case URLError.Code.notConnectedToInternet.rawValue: return .noNetwork(code: statusCode, cause: error)
    case URLError.Code.timedOut.rawValue: return .timeout(code: statusCode, cause: error)
    default:
      if case .explicitlyCancelled = error {
        return .cancelled(code: statusCode, cause: error)
      }
      else {
        return .decoding(code: statusCode, cause: error)
      }
    }
  }

  /// Decodes the data inside a request response to a JSON object of type `Any`.
  ///
  /// - Parameter response: The request response.
  ///
  /// - Throws: When there is an error decoding the data.
  ///
  /// - Returns: The decoded JSON object.
  private func parseResponseData(_ response: AFDataResponse<Data?>) throws -> Any {
    guard let data = response.data else { throw NetworkError2.decoding(code: response.response?.statusCode) }
    return try JSONSerialization.jsonObject(with: data, options: [])
  }

  /// Decodes the data inside a request response into a codable type `T`.
  ///
  /// - Parameter response: The request response.
  ///
  /// - Throws: When there is an error decoding the data.
  ///
  /// - Returns: The decoded object of type `T`.
  private func parseResponseData<T: Codable>(_ response: AFDataResponse<Data?>) throws -> T {
    guard let data = response.data else { throw NetworkError2.decoding(code: response.response?.statusCode) }
    return try JSONDecoder().decode(T.self, from: data)
  }
}
