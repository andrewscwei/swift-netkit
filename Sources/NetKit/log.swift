// © GHOZT

import os.log
import Foundation

public enum LogMode {
  case none
  case compact
  case verbose
}

/// Logs a message to the unified logging system.
///
/// - Parameters:
///   - level: The log level.
///   - isPublic: Specifies if the log is publicly accessible.
///   - mode: Specifies the log mode.
///   - fileName: Name of the file where this function was called.
///   - functionName: Name of the function where this function was called.
///   - lineNumber: Line number where this function was called.
///   - message: The block that returns the message.
func log(_ level: OSLogType = .info, isPublic: Bool = true, mode: LogMode = .none, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line, message: () -> String) {
  guard mode != .none else { return }

#if DEBUG
  let fileName = fileName.components(separatedBy: "/").last?.components(separatedBy: ".").first
  let subsystem = Bundle.main.bundleIdentifier ?? "app"
  let category = "\(fileName ?? "???"):\(lineNumber)"

  switch mode {
  case .compact:
    guard level != .default else { return }
    print(getCompactSymbol(for: level), "[\(category)]", message())
  case .verbose:
    if isPublic {
      os_log("%{public}@", log: OSLog(subsystem: subsystem, category: category), type: level, message())
    }
    else {
      os_log("%{private}@", log: OSLog(subsystem: subsystem, category: category), type: level, message())
    }
  default:
    break
  }
#endif
}

/// Returns the logging symbol (in compact mode) of the specified log level.
///
/// - Parameter level: The log level.
///
/// - Returns: The log symbol.
private func getCompactSymbol(for level: OSLogType) -> String {
  switch level {
  case .fault: return "💀"
  case .error: return "⚠️"
  case .debug: return "👾"
  case .info: return "🤖"
  default: return ""
  }
}
