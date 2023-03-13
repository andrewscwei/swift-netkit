// © GHOZT

import Alamofire
import Foundation
import SwiftyJSON

extension NetworkTransport {
  /// Sends an async multipart request to the `NetworkEndpoint` provided and
  /// parses the response as a `Result` with a success value of codable type
  /// `T`.
  ///
  /// - Parameters:
  ///   - endpoint: The `NetworkEndpoint`.
  ///   - queue: The dispatch queue used for placing the request.
  ///   - tag: Custom tag for identifying this request. One will be generated
  ///          automatically if unspecified.
  ///   - overwriteExisting: Indicates if this request should overwrite an
  ///                        existing request with the same tag. If so, the
  ///                        existing request will be cancelled and this new
  ///                        request will be placed. If `false` and an existing
  ///                        request is active, a new request will not be placed
  ///                        and the existing active request will be returned
  ///                        immediately instead.
  ///   - cancelQuietly: Indicates if this request should cancel quietly without
  ///                    returning an error. If `false`, cancellations will be
  ///                    treated as an error (`NetworkError.cancelled`).
  ///   - completion: Handler invoked when the request completes and a response
  ///                 is received. This handler transforms the raw response into
  ///                 a `Result` with codable type `T` as its success value and
  ///                 a `NetworkError` as its failure value. More fine-grained
  ///                 parsing using the response status code is controlled by
  ///                 the active `NetworkTransportPolicy`, via its member
  ///                 `parseResponse(_:statusCode:)`.
  ///
  /// - Returns: The `Request` object.
  @discardableResult public func upload<T: Decodable>(
    _ endpoint: NetworkEndpoint,
    queue: DispatchQueue = .global(qos: .utility),
    tag: String? = nil,
    overwriteExisting: Bool = true,
    cancelQuietly: Bool = true,
    completion: @escaping (Result<T, Error>) -> Void = { _ in }
  ) -> Request {
    let tag = tag ?? generateTagFromEndpoint(endpoint)

    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) { return existingRequest }

    removeRequestFromQueue(tag: tag)

    log(.debug, mode: logMode) { "Sending multipart \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"..." }

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
      .responseDecodable(of: T.self, queue: queue) { [weak self] in
        guard let weakSelf = self else { return }

        let response = weakSelf.parseResponse($0, for: endpoint, tag: tag)

        if
          cancelQuietly,
          case .failure(let error) = response,
          let networkError = error as? NetworkError,
          case .cancelled = networkError
        {
          log(.debug, mode: weakSelf.logMode) { "Sending multipart \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"... SKIP: Cancelled quietly" }
          return
        }

        completion(response)
      }

    return addRequestToQueue(request: request, tag: tag)
  }

  /// Sends an async multipart request to the `NetworkEndpoint` provided and
  /// parses the response as a `Result` with no success value (i.e. when the
  /// payload is discardable or when the status code is expected to be `204`).
  ///
  /// - Parameters:
  ///   - endpoint: The `NetworkEndpoint`.
  ///   - queue: The dispatch queue used for placing the request.
  ///   - tag: Custom tag for identifying this request. One will be generated
  ///          automatically if unspecified.
  ///   - overwriteExisting: Indicates if this request should overwrite an
  ///                        existing request with the same tag. If so, the
  ///                        existing request will be cancelled and this new
  ///                        request will be placed. If `false` and an existing
  ///                        request is active, a new request will not be placed
  ///                        and the existing active request will be returned
  ///                        immediately instead.
  ///   - cancelQuietly: Indicates if this request should cancel quietly without
  ///                    returning an error. If `false`, cancellations will be
  ///                    treated as an error (`NetworkError.cancelled`).
  ///   - completion: Handler invoked when the request completes and a response
  ///                 is received. This handler transforms the raw response into
  ///                 a `Result` with void as its success value and a
  ///                 `NetworkError` as its failure value. More fine-grained
  ///                 parsing using the response status code is controlled by
  ///                 the active `NetworkTransportPolicy`, via its member
  ///                 `parseResponse(_:statusCode:)`.
  ///
  /// - Returns: The `Request` object.
  @discardableResult public func upload(
    _ endpoint: NetworkEndpoint,
    queue: DispatchQueue = .global(qos: .utility),
    tag: String? = nil,
    overwriteExisting: Bool = true,
    cancelQuietly: Bool = true,
    completion: @escaping (Result<Void, Error>) -> Void = { _ in }
  ) -> Request {
    let tag = tag ?? generateTagFromEndpoint(endpoint)

    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) { return existingRequest }

    removeRequestFromQueue(tag: tag)

    log(.debug, mode: logMode) { "Sending multipart \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"..." }

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
      .response(queue: queue) { [weak self] in
        guard let weakSelf = self else { return }

        let response = weakSelf.parseResponse($0, for: endpoint, tag: tag).map { _ in }

        if
          cancelQuietly,
          case .failure(let error) = response,
          let networkError = error as? NetworkError,
          case .cancelled = networkError
        {
          log(.debug, mode: weakSelf.logMode) { "Sending multipart \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"... SKIP: Cancelled quietly" }
          return
        }

        completion(response)
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

      if let statusCode = statusCode {
        log(.error, mode: logMode) { "Sending multipart \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"... ERR: [\(statusCode)] \(error)" }
        return policy.parseResult(result: .failure(error), statusCode: statusCode)
      }
      else {
        log(.error, mode: logMode) { "Sending multipart \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"... ERR: \(error)" }
        return .failure(NetworkError.from(error))
      }
    case .success(let data):
      guard let statusCode = response.response?.statusCode else {
        log(.error, mode: logMode) { "Sending multipart \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"... ERR: No status code" }
        return .failure(NetworkError.noResponse())
      }

      log(.debug, mode: logMode) { "Sending multipart \(endpoint.method.rawValue.uppercased()) request with tag <\(tag)> to endpoint \"\(endpoint)\"... OK: [\(statusCode)] \(data)" }
      return policy.parseResult(result: .success(data), statusCode: statusCode)
    }
  }

  /// Appends parameters to a multipart form data object. Supported parameters
  /// include raw `Data` (treated as files to be uploaded), urls (also treated
  /// as files to be uploaded), and otherwise JSON encodable values.
  ///
  /// - Parameters:
  ///   - formData: The multipart form data object to append parameters to.
  ///   - parameters: The parameters to append to the multipart form data.
  ///
  /// - Throws:
  ///   - `NetworkError.encodingParameters`: when unable to encode one or more
  ///     parameters.
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
