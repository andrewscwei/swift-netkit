// © GHOZT

import Alamofire
import BaseKit
import Foundation
import SwiftyJSON

extension NetworkTransport {

  /// Sends an async multipart request to the `NetworkEndpoint` provided and parses the response as
  /// a `Result` with a success value of codable type `T`.
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
  @discardableResult public func upload<T: Decodable>(
    _ endpoint: NetworkEndpoint,
    queue: DispatchQueue = .global(qos: .utility),
    tag: String? = nil,
    overwriteExisting: Bool = true,
    completion: @escaping (Result<T, Error>) -> Void = { _ in }
  ) -> Request {
    let tag = tag ?? generateTagFromEndpoint(endpoint)

    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) { return existingRequest }

    removeRequestFromQueue(tag: tag)

    log(.debug, isEnabled: debugMode) { "Sending mutipart \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"..." }

    let request = AF.upload(
      multipartFormData: { formData in
        do {
          try self.appendToMultipartFormData(formData, parameters: endpoint.parameters ?? [:])
        }
        catch {
          return completion(.failure(NetworkError.encoding(cause: error)))
        }
      },
      to: endpoint,
      method: endpoint.method,
      headers: .init(endpoint.headers),
      interceptor: policy
    ) { urlRequest in
      urlRequest.timeoutInterval = endpoint.timeout
    }
      .validate({ urlRequest, response, data in self.policy.validate(response: response) })
      .responseDecodable(of: T.self, queue: queue) { [weak self] response in
        guard let weakSelf = self else { return }
        completion(weakSelf.parseResponse(response, for: endpoint, tag: tag))
      }

    return addRequestToQueue(request: request, tag: tag)
  }

  /// Sends an async multipart request to the `NetworkEndpoint` provided and parses the response as
  /// a `Result` with a success value of a JSON decodable object.
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
  @discardableResult public func upload(
    _ endpoint: NetworkEndpoint,
    queue: DispatchQueue = .global(qos: .utility),
    tag: String? = nil,
    overwriteExisting: Bool = true,
    completion: @escaping (Result<Any, Error>) -> Void = { _ in }
  ) -> Request {
    let tag = tag ?? generateTagFromEndpoint(endpoint)

    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) { return existingRequest }

    removeRequestFromQueue(tag: tag)

    log(.debug, isEnabled: debugMode) { "Sending mutipart \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"..." }

    let request = AF.upload(
      multipartFormData: { formData in
        do {
          try self.appendToMultipartFormData(formData, parameters: endpoint.parameters ?? [:])
        }
        catch {
          return completion(.failure(NetworkError.encoding(cause: error)))
        }
      },
      to: endpoint,
      method: endpoint.method,
      headers: .init(endpoint.headers),
      interceptor: policy
    ) { urlRequest in
      urlRequest.timeoutInterval = endpoint.timeout
    }
      .validate({ urlRequest, response, data in self.policy.validate(response: response) })
      .responseJSON(queue: queue) { [weak self] response in
        guard let weakSelf = self else { return }
        completion(weakSelf.parseResponse(response, for: endpoint, tag: tag))
      }

    return addRequestToQueue(request: request, tag: tag)
  }

  /// Sends an async multipart request to the `NetworkEndpoint` provided and parses the response as
  /// a `Result` with no success value (i.e. when the payload is discardable or when the status code
  /// is expected to be `204`).
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
  @discardableResult public func upload(
    _ endpoint: NetworkEndpoint,
    queue: DispatchQueue = .global(qos: .utility),
    tag: String? = nil,
    overwriteExisting: Bool = true,
    completion: @escaping (Result<Void, Error>) -> Void = { _ in }
  ) -> Request {
    let tag = tag ?? generateTagFromEndpoint(endpoint)

    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) { return existingRequest }

    removeRequestFromQueue(tag: tag)

    log(.debug, isEnabled: debugMode) { "Sending mutipart \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"..." }

    let request = AF.upload(
      multipartFormData: { formData in
        do {
          try self.appendToMultipartFormData(formData, parameters: endpoint.parameters ?? [:])
        }
        catch {
          return completion(.failure(NetworkError.encoding(cause: error)))
        }
      },
      to: endpoint,
      method: endpoint.method,
      headers: .init(endpoint.headers),
      interceptor: policy
    ) { urlRequest in
      urlRequest.timeoutInterval = endpoint.timeout
    }
      .validate({ urlRequest, response, data in self.policy.validate(response: response) })
      .response(queue: queue) { [weak self] response in
        guard let weakSelf = self else { return }
        completion(weakSelf.parseResponse(response, for: endpoint, tag: tag).map { _ in })
      }

    return addRequestToQueue(request: request, tag: tag)
  }

  /// Parses the response returned by an endpoint request into a `Result`.
  ///
  /// - Parameters:
  ///   - response: The response.
  ///   - endpoint: The endpoint.
  ///   - tag: The tag associated with the request.
  ///
  /// - Returns: The parsed result.
  private func parseResponse<T>(_ response: DataResponse<T, AFError>, for endpoint: NetworkEndpoint, tag: String) -> Result<T, Error> {
    switch response.result {
    case .failure(let error):
      let statusCode = response.response?.statusCode
      let networkError = NetworkError.from(error)

      if let statusCode = statusCode {
        log(.error, isEnabled: debugMode) { "Sending multipart \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"... ERR: [\(statusCode)] \(networkError)" }
        return policy.parseResult(result: .failure(networkError), statusCode: statusCode)
      }
      else {
        log(.error, isEnabled: debugMode) { "Sending multipart \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"... ERR: \(networkError)" }
        return .failure(networkError)
      }
    case .success(let data):
      guard let statusCode = response.response?.statusCode else {
        let networkError: NetworkError = .noResponse
        log(.error, isEnabled: debugMode) { "Sending multipart \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"... ERR: \(networkError)" }
        return .failure(networkError)
      }

      log(.debug, isEnabled: debugMode) { "Sending multipart \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"... OK: [\(statusCode)] \(data)" }
      return policy.parseResult(result: .success(data), statusCode: statusCode)
    }
  }

  /// Appends parameters to a multipart form data object. Supported parameters include raw `Data`
  /// (treated as files to be uploaded), urls (also treated as files to be uploaded), and otherwise
  /// JSON encodable values.
  ///
  /// - Parameters:
  ///   - formData: The multipart form data object to append parameters to.
  ///   - parameters: The parameters to append to the multipart form data.
  ///
  /// - Throws:
  ///   - `NetworkError.encodingParameters`: when unable to encode one or more parameters.
  private func appendToMultipartFormData(_ formData: MultipartFormData, parameters: Parameters) throws {
    for (key, value) in parameters {
      if let data = value as? Data {
        formData.append(data, withName: key, fileName: key, mimeType: data.mimeType)
      }
      else {
        let json = JSON(value)

        if let rawString = json.rawString(), let data = rawString.data(using: .utf8) {
          formData.append(data, withName: key)
        }
        else {
          do {
            let data = try json.rawData()
            formData.append(data, withName: key)
          }
          catch {
            throw NetworkError.encoding(cause: error)
          }
        }
      }
    }
  }
}
