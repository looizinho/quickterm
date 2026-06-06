import Foundation

class RuntimeState {
  static let shared = RuntimeState()

  private(set) var workingDirectoryOverride: String?

  func setWorkingDirectory(_ path: String) {
    self.workingDirectoryOverride = path
  }

  var workingDirectory: String {
    if let override = self.workingDirectoryOverride {
      return override
    }
    if let configured = Config.current.commandConfiguration.workingDirectory {
      return configured
    }
    return FileManager.default.currentDirectoryPath
  }
}
