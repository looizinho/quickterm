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

    let expanded = (raw as NSString).expandingTildeInPath
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: expanded, isDirectory: &isDirectory), isDirectory.boolValue else {
      logger.error("Directory does not exist: \(expanded, privacy: .public)")
      return
    }

    RuntimeState.shared.setWorkingDirectory(expanded)
    logger.info("Working directory set to: \(expanded, privacy: .public)")
  }
}
