import Foundation
import os
import ServiceManagement

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UI/LoginItem")

enum LoginItem {
  static func sync(enabled: Bool) {
    let service = SMAppService.mainApp
    do {
      if enabled {
        if service.status != .enabled {
          try service.register()
          logger.info("Registered login item")
        }
      } else {
        if service.status == .enabled {
          try service.unregister()
          logger.info("Unregistered login item")
        }
      }
    } catch {
      logger.error("Failed to sync login item: \(error.localizedDescription, privacy: .public)")
    }
  }
}
