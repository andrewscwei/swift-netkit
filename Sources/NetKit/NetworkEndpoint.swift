// © Sybl

import Alamofire
import Foundation

public protocol NetworkEndpoint: URLRequestConvertible {

  /// The host URL of the endpoint, (i.e. https://www.example.com).
  static var host: String { get }
}
