// © GHOZT

import Alamofire
import Foundation

extension NetworkTransport {

  /// Downloads a file from the specified `URLConvertible` to the specified directory, file name
  /// and extension. If a file already exists at the target path, it is simply replaced with the
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
  ///   - cancelQuietly: Indicates if this request should cancel quietly without returning an error.
  ///                    If `false`, cancellations will be treated as an error
  ///                    (`NetworkError.cancelled`).
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
    cancelQuietly: Bool = true,
    completion: @escaping (Result<URL, Error>) -> Void = { _ in }
  ) -> Request {
    let tag = tag ?? "[DOWNLOAD]\(url)"

    if !overwriteExisting, let existingRequest = getActiveRequest(tag: tag) { return existingRequest }

    removeRequestFromQueue(tag: tag)

    log(.debug, mode: logMode) { "Downloading from URL \"\(url)\" with tag <\(tag)>..." }

    let destination: DownloadRequest.Destination = { (_, _) in
      var fileURL = directory.appendingPathComponent(fileName)

      if let ext = ext {
        fileURL = fileURL.appendingPathExtension(ext)
      }

      return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
    }

    let request = AF.download(url, interceptor: policy, to: destination).response { [weak self] in
      guard let weakSelf = self else { return completion(.failure(NetworkError.unknown)) }

      let response = weakSelf.parseResponse($0, for: url, tag: tag)

      if
        cancelQuietly,
        case .failure(let error) = response,
        let error = error as? NetworkError,
        case .cancelled = error
      {
        return
      }

      completion(response)
    }

    return addRequestToQueue(request: request, tag: tag)
  }

  /// Parses the response returned by a download request into a `Result`.
  ///
  /// - Parameters:
  ///   - response: The response.
  ///   - url: The `URLConvertible`.
  ///   - tag: The tag associated with the request.
  ///
  /// - Returns: The parsed result.
  private func parseResponse(_ response: DownloadResponse<URL?, AFError>, for url: URLConvertible, tag: String) -> Result<URL, Error> {
    switch response.result {
    case .failure(let error):
      let networkError = NetworkError.from(error)
      log(.error, mode: logMode) { "Downloading from URL \"\(url)\" with tag <\(tag)>... ERR: \(networkError)" }
      return .failure(networkError)
    case .success(let fileURL):
      if let fileURL = fileURL {
        log(.debug, mode: logMode) { "Downloading from URL \"\(url)\" with tag <\(tag)>... OK: \(fileURL)" }
        return .success(fileURL)
      }
      else {
        let networkError: NetworkError = .download
        log(.error, mode: logMode) { "Downloading from URL \"\(url)\" with tag <\(tag)>... ERR: \(networkError)" }
        return .failure(networkError)
      }
    }
  }
}
