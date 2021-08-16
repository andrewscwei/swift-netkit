// © Sybl

import Alamofire
import BaseKit
import Foundation

extension NetworkTransport {

  /// Downloads a file from the specified `URLConvertible` to the specified directory, file name and
  /// extension. If a file already exists at the target path, it is simply replaced with the
  /// downloaded file.
  ///
  /// - Parameters:
  ///   - url: The `URLConvertible`.
  ///   - directory: The URL of the local directory to download the file to.
  ///   - fileName: The name of the file to save to (defaults to a random UUID string).
  ///   - ext: Optional extension of the file to save to.
  ///   - tag: Custom tag for identifying this request. One will be generated automatically if
  ///          unspecified.
  ///   - overwriteExisting: Indicates if this request should overwrite an existing request with the
  ///                        same tag. If so, the existing request will be cancelled and this new
  ///                        request will be placed. If `false` and an existing request is active, a
  ///                        new request will not be placed and the existing active request will be
  ///                        returned immediately instead.
  ///   - completion: Handler invoked when the request completes and a response is received. This
  ///                 handler transforms the raw response into a `Result` with the saved file URL as
  ///                 its success value and a `NetworkError` as its failure value.
  @discardableResult public func download(
    from url: URLConvertible,
    to directory: URL,
    fileName: String = UUID().uuidString,
    extension ext: String? = nil,
    tag: String? = nil,
    overwriteExisting: Bool = true,
    completion: @escaping (Result<URL, NetworkError>) -> Void = { _ in }
  ) -> Request {
    let tag = tag ?? "[DOWNLOAD]\(url)"
    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) { return existingRequest }

    removeRequestFromQueue(tag: tag)

    log(.debug) { "Downloading from endpoint \"\(url)\"..." }

    let destination: DownloadRequest.Destination = { (_, _) in
      var fileURL = directory.appendingPathComponent(fileName)

      if let ext = ext {
        fileURL = fileURL.appendingPathExtension(ext)
      }

      return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
    }

    let request = AF.download(url, interceptor: policy, to: destination).response { [weak self] response in
      guard let _ = self else { return completion(.failure(.unknown)) }

      if response.error == nil, let fileURL = response.fileURL {
        log(.debug) { "Downloading from endpoint \"\(url)\"... OK: \(fileURL)" }
        completion(.success(fileURL))
      }
      else {
        log(.error) { "Downloading from endpoint \"\(url)\"... ERR: \(String(describing: response.error))" }
        completion(.failure(.download(cause: response.error)))
      }
    }

    return addRequestToQueue(request: request, tag: tag)
  }

  /// Downloads a file from the specified `URLRequestConvertible` to the specified directory, file
  /// name and extension. If a file already exists at the target path, it is simply replaced with
  /// the downloaded file.
  ///
  /// - Parameters:
  ///   - urlRequest: The `URLRequestConvertible`.
  ///   - directory: The URL of the local directory to download the file to.
  ///   - fileName: The name of the file to save to (defaults to a random UUID string).
  ///   - ext: Optional extension of the file to save to.
  ///   - tag: Custom tag for identifying this request. One will be generated automatically if
  ///          unspecified.
  ///   - overwriteExisting: Indicates if this request should overwrite an existing request with the
  ///                        same tag. If so, the existing request will be cancelled and this new
  ///                        request will be placed. If `false` and an existing request is active, a
  ///                        new request will not be placed and the existing active request will be
  ///                        returned immediately instead.
  ///   - completion: Handler invoked when the request completes and a response is received. This
  ///                 handler transforms the raw response into a `Result` with the saved file URL as
  ///                 its success value and a `NetworkError` as its failure value.
  @discardableResult public func download(
    from urlRequest: URLRequestConvertible,
    to directory: URL,
    fileName: String = UUID().uuidString,
    extension ext: String? = nil,
    tag: String? = nil,
    overwriteExisting: Bool = true,
    completion: @escaping (Result<URL, NetworkError>) -> Void = { _ in }
  ) -> Request {
    let tag = tag ?? "[DOWNLOAD]\(urlRequest)"

    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) { return existingRequest }

    removeRequestFromQueue(tag: tag)

    log(.debug) { "Downloading from endpoint \"\(urlRequest)\"..." }

    let destination: DownloadRequest.Destination = { (_, _) in
      var fileURL = directory.appendingPathComponent(fileName)

      if let ext = ext {
        fileURL = fileURL.appendingPathExtension(ext)
      }

      return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
    }

    let request = AF.download(urlRequest, interceptor: policy, to: destination).response { [weak self] response in
      guard let _ = self else { return completion(.failure(.unknown)) }

      if response.error == nil, let fileURL = response.fileURL {
        log(.debug) { "Downloading from endpoint \"\(urlRequest)\"... OK: \(fileURL)" }
        completion(.success(fileURL))
      }
      else {
        log(.error) { "Downloading from endpoint \"\(urlRequest)\"... ERR: \(String(describing: response.error))" }
        completion(.failure(.download(cause: response.error)))
      }
    }

    return addRequestToQueue(request: request, tag: tag)
  }
}
