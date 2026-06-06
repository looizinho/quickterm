import AppKit
import Foundation
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UI/SlashCommands/Quit")

struct QuitCommand: SlashCommand {
  static let name = "quit"

  func execute(args _: [String]) {
    logger.info("Quitting application")
    DispatchQueue.main.async {
      NSApplication.shared.terminate(nil)
    }
  }
}
