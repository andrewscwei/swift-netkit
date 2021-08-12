// © Sybl

import Alamofire
import BaseKit
import Foundation
import SwiftyJSON

extension NetworkTransport {

  /// Sends an async multipart request based on the `URLRequestConvertible` provided and parses the
  /// response as a `Result` with a success value of codable type `T`.
  ///
  /// - Parameters:
  ///   - urlRequest: The `URLRequestConvertible`.
  ///   - parameters: The request parameters.
  ///   - queue: The dispatch queue used for placing the request.
  ///   - tag: Tag for identifying this request—if unspecified, a random UUID will be used.
  ///   - overwriteExisting: Indicates if this request should overwrite an existing request with the
  ///                        same tag. If so, the existing request will be cancelled and this new
  ///                        request will be placed. If `false` and an existing request is active, a
  ///                        new request will not be placed and the existing active request will be
  ///                        returned immediately instead.
  ///   - responseHandler: Handler invoked when the request completes and a response is received.
  ///                      This handler transforms the raw response into a `Result` with codable
  ///                      type `T` as its success value and a `NetworkError` as its failure value.
  ///                      More fine-grained parsing using the response status code is controlled by
  ///                      the active `NetworkTransportPolicy`, via its member
  ///                      `parseResponse(_:statusCode:)`.
  ///
  /// - Returns: The `Request` object.
  @discardableResult public func upload<T: Decodable>(_ urlRequest: URLRequestConvertible, parameters: [String: Any] = [:], queue: DispatchQueue = .global(qos: .utility), tag: String = UUID().uuidString, overwriteExisting: Bool = true, responseHandler: @escaping (Result<T, Error>) -> Void = { _ in }) -> Request {
    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) { return existingRequest }

    removeRequestFromQueue(tag: tag)

    log(.debug) { "Sending multipart request to endpoint \"\(urlRequest)\"..." }

    let request = AF.upload(multipartFormData: { [weak self] formData in
      guard let weakSelf = self else { return responseHandler(.failure(NetworkError.unknown)) }

      do {
        try weakSelf.appendToMultipartFormData(formData, parameters: parameters)
      }
      catch {
        return responseHandler(.failure(NetworkError.encoding(cause: error)))
      }
    }, with: urlRequest, interceptor: policy).response(queue: queue) { [weak self] response in
      guard let weakSelf = self else { return responseHandler(.failure(NetworkError.unknown)) }

      let result: Result<T, Error> = weakSelf.parseResponse(response)
      log(.debug) { "Sending multipart request to endpoint \"\(urlRequest)\"... OK: \(result)" }
      responseHandler(result)
    }

    return addRequestToQueue(request: request, tag: tag)
  }

  /// Sends an async multipart request based on the `URLRequestConvertible` provided and parses the
  /// response as a `Result` with a success value of a JSON decodable object.
  ///
  /// - Parameters:
  ///   - urlRequest: The `URLRequestConvertible`.
  ///   - parameters: The request parameters.
  ///   - queue: The dispatch queue used for placing the request.
  ///   - tag: Tag for identifying this request—if unspecified, a random UUID will be used.
  ///   - overwriteExisting: Indicates if this request should overwrite an existing request with the
  ///                        same tag. If so, the existing request will be cancelled and this new
  ///                        request will be placed. If `false` and an existing request is active, a
  ///                        new request will not be placed and the existing active request will be
  ///                        returned immediately instead.
  ///   - responseHandler: Handler invoked when the request completes and a response is received.
  ///                      This handler transforms the raw response into a `Result` with a JSON
  ///                      decodable object as its success value and a `NetworkError` as its failure
  ///                      value. More fine-grained parsing using the response status code is
  ///                      controlled by the active `NetworkTransportPolicy`, via its member
  ///                      `parseResponse(_:statusCode:)`.
  ///
  /// - Returns: The `Request` object.
  @discardableResult public func upload(_ urlRequest: URLRequestConvertible, parameters: [String: Any] = [:], queue: DispatchQueue = .global(qos: .utility), tag: String = UUID().uuidString, overwriteExisting: Bool = true, responseHandler: @escaping (Result<Any, Error>) -> Void = { _ in }) -> Request {
    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) { return existingRequest }

    removeRequestFromQueue(tag: tag)

    log(.debug) { "Sending multipart request to endpoint \"\(urlRequest)\"..." }

    let request = AF.upload(multipartFormData: { [weak self] formData in
      guard let weakSelf = self else { return responseHandler(.failure(NetworkError.unknown)) }

      do {
        try weakSelf.appendToMultipartFormData(formData, parameters: parameters)
      }
      catch {
        return responseHandler(.failure(NetworkError.encoding(cause: error)))
      }
    }, with: urlRequest, interceptor: policy).response(queue: queue) { [weak self] response in
      guard let weakSelf = self else { return responseHandler(.failure(NetworkError.unknown)) }

      let result: Result<Any, Error> = weakSelf.parseResponse(response)
      log(.debug) { "Sending multipart request to endpoint \"\(urlRequest)\"... OK: \(result)" }
      responseHandler(result)
    }

    return addRequestToQueue(request: request, tag: tag)
  }

  /// Sends an async multipart request based on the `URLRequestConvertible` provided and parses the
  /// response as a `Result` with no success value (i.e. when the payload is discardable or when the
  /// status code is expected to be `204`).
  ///
  /// - Parameters:
  ///   - urlRequest: The `URLRequestConvertible`.
  ///   - parameters: The request parameters.
  ///   - queue: The dispatch queue used for placing the request.
  ///   - tag: Tag for identifying this request—if unspecified, a random UUID will be used.
  ///   - overwriteExisting: Indicates if this request should overwrite an existing request with the
  ///                        same tag. If so, the existing request will be cancelled and this new
  ///                        request will be placed. If `false` and an existing request is active, a
  ///                        new request will not be placed and the existing active request will be
  ///                        returned immediately instead.
  ///   - responseHandler: Handler invoked when the request completes and a response is received.
  ///                      This handler transforms the raw response into a `Result` with void as its
  ///                      success value and a `NetworkError` as its failure value. More
  ///                      fine-grained parsing using the response status code is controlled by the
  ///                      active `NetworkTransportPolicy`, via its member
  ///                      `parseResponse(_:statusCode:)`.
  ///
  /// - Returns: The `Request` object.
  @discardableResult public func upload(_ urlRequest: URLRequestConvertible, parameters: [String: Any] = [:], queue: DispatchQueue = .global(qos: .utility), tag: String = UUID().uuidString, overwriteExisting: Bool = true, responseHandler: @escaping (Result<Void, Error>) -> Void = { _ in }) -> Request {
    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) { return existingRequest }

    removeRequestFromQueue(tag: tag)

    log(.debug) { "Sending multipart request to endpoint \"\(urlRequest)\"..." }

    let request = AF.upload(multipartFormData: { [weak self] formData in
      guard let weakSelf = self else { return responseHandler(.failure(NetworkError.unknown)) }

      do {
        try weakSelf.appendToMultipartFormData(formData, parameters: parameters)
      }
      catch {
        return responseHandler(.failure(NetworkError.encoding(cause: error)))
      }
    }, with: urlRequest, interceptor: policy).response(queue: queue) { [weak self] response in
      guard let weakSelf = self else { return responseHandler(.failure(NetworkError.unknown)) }

      let result: Result<Void, Error> = weakSelf.parseResponse(response)
      log(.debug) { "Sending multipart request to endpoint \"\(urlRequest)\"... OK: \(result)" }
      responseHandler(result)
    }

    return addRequestToQueue(request: request, tag: tag)
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
      else if let url = value as? URL, let data = try? Data.init(contentsOf: url) {
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
