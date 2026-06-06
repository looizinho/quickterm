import Foundation

protocol SlashCommand {
  static var name: String { get }
  func execute(args: [String])
}
