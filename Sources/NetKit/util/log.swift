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
func log(_ level: OSLogType = .default, isPublic: Bool = true, mode: LogMode = .none, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line, message: () -> String) {
  guard mode != .none else { return }

#if DEBUG
  let fileName = fileName.components(separatedBy: "/").last?.components(separatedBy: ".").first
  let subsystem = Bundle.main.bundleIdentifier ?? "app"

  switch mode {
  case .compact:
    print(getCompactSymbol(for: level), message())
  case .verbose:
    let category = "\(fileName ?? "???"):\(lineNumber)"

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
/// - Parameters:
///   - level: The log level.
///
/// - Returns: The log symbol.
private func getCompactSymbol(for level: OSLogType) -> String {
  switch level {
  case .fault: return "💀🌐"
  case .error: return "⚠️🌐"
  default: return "🌐"
  }
}
