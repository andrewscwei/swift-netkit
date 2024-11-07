import os.log
import Foundation

struct Log: Sendable {
  enum Mode {
    case none
    case console
  }

  let mode: Mode

  func info(_ message: String) { log(message, level: .info) }
  func debug(_ message: String) { log(message, level: .debug) }
  func error(_ message: String) { log(message, level: .error) }
  func fault(_ message: String) { log(message, level: .fault) }

  private func log(_ message: String, level: OSLogType = .info) {
    guard mode != .none else { return }

#if !DEBUG
    guard  level != .debug else { return }
#endif

    let prefix = "[🌐]"
    let message = [prefix, getSymbol(for: level), message].compactMap { $0 }.joined(separator: " ")

    print(message)
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
let _log = Log(mode: .console)
#else
let _log = Log(mode: .none)
#endif
