import Foundation
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UI/SlashCommands/Registry")

class SlashCommandRegistry {
  static let shared = SlashCommandRegistry()

  private var commands: [String: SlashCommand] = [:]

  init() {
    self.register(DirCommand())
  }

  func register(_ command: SlashCommand) {
    self.commands[type(of: command).name] = command
  }

  /// Returns true if the input was a slash command (handled or unknown),
  /// false if it should be executed as a shell command.
  @discardableResult
  func handle(_ input: String) -> Bool {
    let trimmed = input.trimmingCharacters(in: .whitespaces)
    guard trimmed.hasPrefix("/") else { return false }

    let body = trimmed.dropFirst()
    let parts = body.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true).map(String.init)
    guard let name = parts.first else { return false }

    guard let command = self.commands[name] else {
      logger.error("Unknown slash command: \(name, privacy: .public)")
      return true
    }

    let args: [String]
    if parts.count > 1 {
      args = parts[1].split(separator: " ", omittingEmptySubsequences: true).map(String.init)
    } else {
      args = []
    }
    command.execute(args: args)
    return true
  }
}
