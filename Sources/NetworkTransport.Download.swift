import Alamofire
import Foundation

extension NetworkTransport {

  /// Downloads a file from the specified `URLConvertible` to the specified
  /// directory, file name and extension. If a file already exists at the target
  /// path, it is simply replaced with the downloaded file.
  ///
  /// - Parameters:
  ///   - url: The `URLConvertible`.
  ///   - directory: The URL of the local directory to download the file to.
  ///   - fileName: The name of the file to save to (defaults to a random UUID
  ///               string).
  ///   - ext: Optional extension of the file to save to.
  ///   - queue: The dispatch queue used for placing the request.
  ///   - tag: Custom identifier tag, auto-generated if unspecified.
  ///   - replace: Indicates if this request should repalce an existing active
  ///              request with the same tag by cancelling it.
  ///
  /// - Returns: The file URL of the downloaded file.
  @discardableResult
  public func download(
    from url: URLConvertible,
    to directory: URL,
    fileName: String = UUID().uuidString,
    extension ext: String? = nil,
    tag: String? = nil,
    replace: Bool = false
  ) async throws -> URL {
    let tag = tag ?? generateTag(from: String(describing: url))
    let request = createRequest(from: url, to: directory, fileName: fileName, extension: ext, tag: tag, replace: replace)

    _log.debug { "<\(tag)> Downloading...\n↘︎ url=\(url)" }

    defer {
      removeRequestFromQueue(tag: tag)
    }

    let response = await request
      .validate { @Sendable _, res, _ in self.policy.validateStatusCode(res.statusCode) }
      .serializingDownloadedFileURL()
      .response

    let statusCode = response.response?.statusCode

    do {
      let fileURL = try response.result.get()

      _log.debug { "<\(tag)> Downloading... [\(statusCode ?? 0)] OK\n↘︎ file=\(fileURL)" }

      return fileURL
    }
    catch {
      let networkError = NetworkError.from(error)

      _log.error { "<\(tag)> Downloading... [\(statusCode ?? 0)] \(NetworkError.isCancelled(networkError) ? "CANCEL" : "ERR")\n↘︎ error=\(networkError)" }

      throw networkError
    }
  }

  private func createRequest(from url: URLConvertible, to directory: URL, fileName: String, extension ext: String?, tag: String, replace: Bool) -> DownloadRequest {
    if !replace, let request = getActiveRequest(tag: tag) as? DownloadRequest {
      return request
    }

    removeRequestFromQueue(tag: tag, forceCancel: true)

    let destination: DownloadRequest.Destination = { (_, _) in
      var fileURL = directory.appendingPathComponent(fileName)

      if let ext = ext {
        fileURL = fileURL.appendingPathExtension(ext)
      }

      return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
    }

    let request = AF.download(
      url,
      interceptor: policy,
      to: destination
    )

    return addRequestToQueue(request, tag: tag)
  }
}
