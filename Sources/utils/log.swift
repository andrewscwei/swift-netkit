import os.log
import Foundation

struct Log: Sendable {
  enum Mode {
    case none
    case unified
  }

  let mode: Mode

  func info(isPublic: Bool = true, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line, _ message: () -> String) { log(level: .info, isPublic: isPublic, fileName: fileName, functionName: functionName, lineNumber: lineNumber, message) }
  func debug(isPublic: Bool = true, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line, _ message: () -> String) { log(level: .debug, isPublic: isPublic, fileName: fileName, functionName: functionName, lineNumber: lineNumber, message) }
  func error(isPublic: Bool = true, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line, _ message: () -> String) { log(level: .error, isPublic: isPublic, fileName: fileName, functionName: functionName, lineNumber: lineNumber, message) }
  func fault(isPublic: Bool = true, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line, _ message: () -> String) { log(level: .fault, isPublic: isPublic, fileName: fileName, functionName: functionName, lineNumber: lineNumber, message) }

  private func log(level: OSLogType = .info, isPublic: Bool, fileName: String, functionName: String, lineNumber: Int, _ message: () -> String) {
    guard mode != .none else { return }

#if !DEBUG
    guard  level != .debug else { return }
#endif

    let prefix = "[🌐]"
    let message = [prefix, getSymbol(for: level), message()].compactMap { $0 }.joined(separator: " ")
    let fileName = fileName.components(separatedBy: "/").last?.components(separatedBy: ".").first
    let subsystem = "\(Bundle.main.bundleIdentifier ?? "app").netkit"
    let category = "\(fileName ?? "???"):\(lineNumber)"

    if isPublic {
      os_log("%{public}@", log: OSLog(subsystem: subsystem, category: category), type: level, message)
    }
    else {
      os_log("%{private}@", log: OSLog(subsystem: subsystem, category: category), type: level, message)
    }
  }

  private func getSymbol(for level: OSLogType) -> String? {
    switch level {
    case .fault: return "💀"
    case .error: return "⚠️"
    case .debug: return "👾"
    case .info: return "ℹ️"
    default: return nil
    }
  }
}

#if NETKIT_DEBUG
let _log = Log(mode: .unified)
#else
let _log = Log(mode: .none)
#endif
