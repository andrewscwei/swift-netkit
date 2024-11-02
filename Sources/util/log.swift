import os.log
import Foundation

struct Log: Sendable {
  enum Mode {
    case none
    case unified
    case console
  }

  let mode: Mode

  func `default`(_ message: String, isPublic: Bool = true, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
    log(message, level: .default, isPublic: isPublic, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
  }

  func info(_ message: String, isPublic: Bool = true, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
    log(message, level: .info, isPublic: isPublic, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
  }

  func debug(_ message: String, isPublic: Bool = true, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
    log(message, level: .debug, isPublic: isPublic, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
  }

  func error(_ message: String, isPublic: Bool = true, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
    log(message, level: .error, isPublic: isPublic, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
  }

  func fault(_ message: String, isPublic: Bool = true, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
    log(message, level: .fault, isPublic: isPublic, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
  }

  private func log(_ message: String, level: OSLogType = .info, isPublic: Bool, fileName: String, functionName: String, lineNumber: Int) {
    guard mode != .none else { return }

#if !DEBUG
    guard  level != .debug else { return }
#endif

    if mode == .unified {
      let fileName = fileName.components(separatedBy: "/").last?.components(separatedBy: ".").first
      let subsystem = Bundle.main.bundleIdentifier ?? "app"
      let category = "\(fileName ?? "???"):\(lineNumber)"

      if isPublic {
        os_log("%{public}@", log: OSLog(subsystem: subsystem, category: category), type: level, message)
      }
      else {
        os_log("%{private}@", log: OSLog(subsystem: subsystem, category: category), type: level, message)
      }
    }
    else {
      guard level != .default else { return }
      print(getSymbol(for: level), message)
    }
  }

  private func getSymbol(for level: OSLogType) -> String {
    switch level {
    case .fault: return "💀"
    case .error: return "⚠️"
    case .debug: return "👾"
    case .info: return "🤖"
    default: return ""
    }
  }
}

#if NETKIT_DEBUG
let _log = Log(mode: .console)
#else
let _log = Log(mode: .none)
#endif
