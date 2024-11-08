import Alamofire
import Foundation
import SwiftyJSON

extension NetworkTransport {

  /// Sends a multipart request to a `NetworkEndpoint`, returning data of type
  /// `R` from mapping the decodable response payload of type `T`.
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
  public func upload<T: Decodable & Sendable, R: Decodable & Sendable>(
    _ endpoint: NetworkEndpoint,
    tag: String? = nil,
    replace: Bool = false,
    map: @escaping (T) throws -> R
  ) async throws -> R {
    let tag = tag ?? generateTag(from: endpoint)
    let request = createRequest(endpoint, tag: tag, replace: replace)

    _log.debug { "<\(tag)> Uploading to \(endpoint)..." }

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

      _log.debug { "<\(tag)> Uploading to \"\(endpoint)\"... [\(statusCode ?? 0)] OK" }
      _log.debug { "↘︎ payload=\(data)" }

      return try map(data)
    }
    catch {
      let networkError = NetworkError.from(error)

      if
        let data = Empty.value as? T,
        case .decoding(_, _, let cause) = networkError,
        case .responseSerializationFailed(let reason) = cause as? AFError
      {
        switch reason {
        case .inputDataNilOrZeroLength, .invalidEmptyResponse:
          _log.debug { "<\(tag)> Uploading to \"\(endpoint)\"... [\(statusCode ?? 0)] OK" }
          _log.debug { "↘︎ payload=\(data)" }

          return try map(data)
        default:
          break
        }
      }

      _log.error { "<\(tag)> Uploading to \(endpoint)... [\(statusCode ?? 0)] \(NetworkError.isCancelled(networkError) ? "CANCEL" : "ERR"): \(networkError)" }

      if let data = response.data {
        _log.error { "↘︎ payload=\(String(data: data, encoding: .utf8) ?? "<empty>")" }
      }

      throw networkError
    }
  }

  /// Sends a multipart request to a `NetworkEndpoint`, returning decodable data
  /// of type `T` from the response.
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
  ///
  /// - Returns: The decoded response data.
  public func upload<T: Decodable & Sendable>(
    _ endpoint: NetworkEndpoint,
    tag: String? = nil,
    replace: Bool = false
  ) async throws -> T {
    return try await upload(endpoint, tag: tag, replace: replace) { $0 }
  }

  /// Sends a multipart request to a `NetworkEndpoint`, ignoring any response
  /// data.
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
  public func upload(
    _ endpoint: NetworkEndpoint,
    tag: String? = nil,
    replace: Bool = false
  ) async throws {
    let _: Empty = try await upload(endpoint, tag: tag, replace: replace)
  }

  private func createRequest(_ endpoint: NetworkEndpoint, tag: String, replace: Bool) -> UploadRequest {
    if !replace, let request = getActiveRequest(tag: tag) as? UploadRequest {
      return request
    }

    removeRequestFromQueue(tag: tag, forceCancel: true)

    let request = AF.upload(
      multipartFormData: { try? self.appendToMultipartFormData($0, parameters: endpoint.parameters ?? [:]) },
      to: endpoint,
      method: endpoint.method,
      headers: .init(endpoint.headers),
      interceptor: policy,
      requestModifier: { $0.timeoutInterval = endpoint.timeout }
    )

    return addRequestToQueue(request, tag: tag)
  }

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
