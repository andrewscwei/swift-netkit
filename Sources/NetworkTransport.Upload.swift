import Alamofire
import Foundation
import SwiftyJSON

extension NetworkTransport {

  /// Sends a multipart request to a `NetworkEndpoint`, returning decodable data
  /// of type `T` from the response.
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
  public func upload<T: Decodable & Sendable>(
    _ endpoint: NetworkEndpoint,
    tag: String? = nil,
    replace: Bool = false
  ) async throws -> T {
    let tag = tag ?? generateTag(from: endpoint)

    _log.debug("<\(tag)> Uploading to \(endpoint)...")

    let request = createRequest(endpoint, tag: tag, replace: replace)
    let response = await request.serializingDecodable(T.self).response
    let statusCode = response.response?.statusCode

    defer {
      removeRequestFromQueue(tag: tag)
    }

    do {
      let data = try policy.parseResponse(response)

      _log.debug("<\(tag)> Uploading to \"\(endpoint)\"... [\(statusCode ?? 0)] OK")
      _log.debug("> data=\(data)")

      return data
    }
    catch {
      if let error = error as? NetworkError, case .cancelled = error {
        _log.debug("<\(tag)> Uploading to \"\(endpoint)\"... [\(statusCode ?? 0)] CANCEL: \(error)")
      }
      else {
        _log.error("<\(tag)> Uploading to \"\(endpoint)\"... [\(statusCode ?? 0)] ERR: \(error)")

        if let payload = response.data, let json = try? JSONSerialization.jsonObject(with: payload) {
          _log.error("> payload = \(json)")
        }
      }

      throw error
    }
  }

  /// Sends a multipart request to a `NetworkEndpoint`, ignoring any response
  /// data.
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
  public func upload(
    _ endpoint: NetworkEndpoint,
    tag: String? = nil,
    replace: Bool = false
  ) async throws {
    let tag = tag ?? generateTag(from: endpoint)

    _log.debug("<\(tag)> Uploading to \(endpoint)...")

    let request = createRequest(endpoint, tag: tag, replace: replace)
    let response = await request.serializingDecodable(Empty.self).response
    let statusCode = response.response?.statusCode

    defer {
      removeRequestFromQueue(tag: tag)
    }

    do {
      try policy.parseResponse(response)

      _log.debug("<\(tag)> Uploading to \"\(endpoint)\"... [\(statusCode ?? 0)] OK")
    }
    catch {
      if let error = error as? NetworkError, case .cancelled = error {
        _log.debug("<\(tag)> Uploading to \"\(endpoint)\"... [\(statusCode ?? 0)] CANCEL: \(error)")
      }
      else {
        _log.error("<\(tag)> Uploading to \"\(endpoint)\"... [\(statusCode ?? 0)] ERR: \(error)")

        if let payload = response.data, let json = try? JSONSerialization.jsonObject(with: payload) {
          _log.error("> payload = \(json)")
        }
      }

      throw error
    }
  }

  private func createRequest(_ endpoint: NetworkEndpoint, tag: String, replace: Bool) -> UploadRequest {
    if !replace, let request = getActiveRequest(tag: tag) as? UploadRequest {
      return request
    }
    else {
      removeRequestFromQueue(tag: tag)

      let request = AF.upload(
        multipartFormData: { try? self.appendToMultipartFormData($0, parameters: endpoint.parameters ?? [:]) },
        to: endpoint,
        method: endpoint.method,
        headers: .init(endpoint.headers),
        interceptor: policy,
        requestModifier: { $0.timeoutInterval = endpoint.timeout }
      )
        .validate { _, _, _ in .success(()) }

      addRequestToQueue(request: request, tag: tag)

      return request
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
  ///   - `NetworkError.encoding`: when unable to encode one or more parameters.
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
