import Foundation
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UI/SlashCommands/Dir")

struct DirCommand: SlashCommand {
  static let name = "dir"

  func execute(args: [String]) {
    guard let raw = args.first else {
      logger.info("Current working directory: \(RuntimeState.shared.workingDirectory, privacy: .public)")
      return
    }

    let resolved: String
    if raw.hasPrefix("/") {
      resolved = raw
    } else if raw.hasPrefix("~") {
      resolved = (raw as NSString).expandingTildeInPath
    } else {
      resolved = (RuntimeState.shared.workingDirectory as NSString).appendingPathComponent(raw)
    }
    let standardized = (resolved as NSString).standardizingPath

    var isDirectory: ObjCBool = false
    guard
      FileManager.default.fileExists(atPath: standardized, isDirectory: &isDirectory),
      isDirectory.boolValue
    else {
      logger.error("Directory does not exist: \(standardized, privacy: .public)")
      return
    }

    RuntimeState.shared.setWorkingDirectory(standardized)
    logger.info("Working directory set to: \(standardized, privacy: .public)")
  }
}
