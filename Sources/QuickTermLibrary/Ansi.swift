import SwiftUI

public struct DecoratedString {
  private let parsed: ANSIParseTree
  public let value: String

  public init(fromString text: String) {
    self.parsed = ANSIParser.parse(text)
    self.value = text
  }

  public var text: Text {
    var rendered = Text("")
    var activeFormatting: ANSIGraphicsModes = []
    var currentTextBuffer = ""

    var index = self.value.startIndex
    while index < self.value.endIndex {
      // Check if this position has an escape sequence
      if let boundedSequence = self.parsed.escapeSequences[index] {
        // Flush any pending text with current formatting
        if !currentTextBuffer.isEmpty {
          rendered = rendered + applyFormatting(Text(currentTextBuffer), modes: activeFormatting)
          currentTextBuffer = ""
        }

        // Process the escape sequence
        if case let .graphicsModes(modes) = boundedSequence.sequence {
          // Handle reset specially
          if modes.contains(.reset) {
            activeFormatting.removeAll()
          } else {
            activeFormatting.formUnion(modes)
          }
        }

        // Skip past the entire escape sequence
        for _ in 0 ..< boundedSequence.count {
          index = self.value.index(after: index)
          if index >= self.value.endIndex {
            break
          }
        }
        continue
      }

      // Check if this is a control character
      if let controlChar = self.parsed.controlCharacters[index] {
        // Flush pending text
        if !currentTextBuffer.isEmpty {
          rendered = rendered + applyFormatting(Text(currentTextBuffer), modes: activeFormatting)
          currentTextBuffer = ""
        }

        // Handle specific control characters
        switch controlChar {
        case .bell:
          rendered = rendered + Text("!")
        case .linefeed, .carriageReturn:
          rendered = rendered + Text("\n")
        default:
          break
        }

        index = self.value.index(after: index)
        continue
      }

      // Regular character - add to buffer
      currentTextBuffer.append(self.value[index])
      index = self.value.index(after: index)
    }

    // Flush any remaining text
    if !currentTextBuffer.isEmpty {
      rendered = rendered + applyFormatting(Text(currentTextBuffer), modes: activeFormatting)
    }

    return rendered
  }

  private func applyFormatting(_ text: Text, modes: ANSIGraphicsModes) -> Text {
    var result = text

    for mode in modes {
      switch mode {
      case .bold:
        result = result.bold()
      case .dim:
        break
      case .italic:
        result = result.italic()
      case .underline:
        result = result.underline()
      case .strikethrough:
        result = result.strikethrough()
      case .inverse:
        break
      case .invisible:
        break
      case .blinking:
        break
      case .foreground(let color):
        result = result.foregroundColor(color)
      case .background:
        break
      case .reset:
        break
      }
    }

    return result
  }

  public var hasBell: Bool {
    self.parsed.controlCharacters.values.contains(.bell)
  }
}

public enum ASCIIControlCharacter: Character {
  case bell = "\u{0007}"
  case backspace = "\u{0008}"
  case horizontalTab = "\u{0009}"
  case linefeed = "\u{000A}"
  case verticalTab = "\u{000B}"
  case formfeed = "\u{000C}"
  case carriageReturn = "\u{000D}"
  case escapeCharacter = "\u{001B}"
  case deleteCharacter = "\u{007F}"
}

public typealias ANSIGraphicsModes = Set<ANSIGraphicsMode>

public enum ANSIGraphicsMode: Equatable, Hashable {
  case reset, bold, dim, italic, underline, blinking, inverse, invisible, strikethrough, foreground(Color),
       background(Color)

  public static func == (lhs: ANSIGraphicsMode, rhs: ANSIGraphicsMode) -> Bool {
    switch (lhs, rhs) {
    case let (.foreground(a), .foreground(b)), let (.background(a), .background(b)):
      return a == b
    case (.reset, .reset), (.bold, .bold), (.dim, .dim), (.italic, .italic), (.underline, .underline),
         (.blinking, .blinking), (.inverse, .inverse), (.invisible, .invisible), (.strikethrough, .strikethrough):
      return true
    default:
      return false
    }
  }

  public func hash(into hasher: inout Hasher) {
    switch self {
    case let .foreground(a):
      hasher.combine("foreground")
      hasher.combine(a)
    case let .background(a):
      hasher.combine("background")
      hasher.combine(a)
    case .reset:
      hasher.combine("reset")
    case .bold:
      hasher.combine("bold")
    case .dim:
      hasher.combine("dim")
    case .italic:
      hasher.combine("italic")
    case .underline:
      hasher.combine("underline")
    case .blinking:
      hasher.combine("blinking")
    case .inverse:
      hasher.combine("inverse")
    case .invisible:
      hasher.combine("invisible")
    case .strikethrough:
      hasher.combine("strikethrough")
    }
  }
}

public enum ANSIEscapeSequence: Equatable {
  case cursorControl, eraseFunction, graphicsModes(ANSIGraphicsModes), screenMode

  public static func == (lhs: ANSIEscapeSequence, rhs: ANSIEscapeSequence) -> Bool {
    switch (lhs, rhs) {
    case let (.graphicsModes(a), .graphicsModes(b)):
      return a == b
    case (.cursorControl, .cursorControl), (.eraseFunction, .eraseFunction), (.screenMode, .screenMode):
      return true
    default:
      return false
    }
  }
}

public typealias BoundedEscapeSequence = (count: Int, sequence: ANSIEscapeSequence)

public typealias ANSIParseTree = (
  controlCharacters: [String.Index: ASCIIControlCharacter],
  escapeSequences: [String.Index: BoundedEscapeSequence]
)

public enum ANSIParser {
  // See https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
  private static let cursorControlPattern = #"^\[(([Hsu])|(\d+;\d+)([Hf])|(\d+)([ABCDEFG])|(6n))"#
  private static let eraseFunctionPattern = #"^\[([012]?)([JK])"#
  private static let screenModePattern = #"^\[=(\d+)([hl])"#
  private static let graphicsModePattern = #"^\[(\d+)((;\d+)*)m"#

  public static func parse(_ text: String) -> ANSIParseTree {
    var controlCharacters: [String.Index: ASCIIControlCharacter] = [:]
    var escapeSequences: [String.Index: BoundedEscapeSequence] = [:]

    for var i in 0 ..< text.count {
      let index = text.index(text.startIndex, offsetBy: i)
      if let controlCharacter = ASCIIControlCharacter(rawValue: text[index]) {
        controlCharacters[index] = controlCharacter

        if controlCharacter == ASCIIControlCharacter.escapeCharacter {
          let sequenceIndex = text.index(text.startIndex, offsetBy: i + 1)
          if let escapeSequence = parseEscapeSequence(text[sequenceIndex ..< text.endIndex], &i) {
            escapeSequences[index] = escapeSequence
          }
        }
      }
    }

    return (controlCharacters, escapeSequences)
  }

  private static func extractMatches(_ text: Substring, _ pattern: String, _ groups: Int) -> [Substring]? {
    do {
      let regex = try NSRegularExpression(pattern: pattern)
      if let match = regex.firstMatch(in: String(text), range: NSRange(text.startIndex..., in: text)) {
        var parts: [Substring] = []
        for i in 0 ..< groups {
          if let range = Range(match.range(at: i), in: text) {
            parts.append(text[range])
          } else {
            parts.append("")
          }
        }
        return parts
      }
    } catch {
      // Do nothing
    }

    return nil
  }

  private static func parseCursorControl(_ text: Substring) -> BoundedEscapeSequence? {
    guard let matches = extractMatches(text, cursorControlPattern, 7) else {
      return nil
    }

    let length = 1 + matches[0].count
    let escapeSequence = ANSIEscapeSequence.cursorControl
    return (length, escapeSequence)
  }

  private static func parseEraseFunction(_ text: Substring) -> BoundedEscapeSequence? {
    guard let matches = extractMatches(text, eraseFunctionPattern, 2) else {
      return nil
    }

    let length = 1 + matches[0].count
    let escapeSequence = ANSIEscapeSequence.eraseFunction
    return (length, escapeSequence)
  }

  private static func parseScreenMode(_ text: Substring) -> BoundedEscapeSequence? {
    guard let matches = extractMatches(text, screenModePattern, 2) else {
      return nil
    }

    let length = 1 + matches[0].count
    let escapeSequence = ANSIEscapeSequence.screenMode
    return (length, escapeSequence)
  }

  private static func parseGraphicsModes(_ text: Substring) -> BoundedEscapeSequence? {
    guard let matches = extractMatches(text, graphicsModePattern, 3) else {
      return nil
    }

    var parameters: Set<Int> = []
    parameters.insert(Int(matches[1])!)
    for parameter in matches[2].split(separator: ";") {
      parameters.insert(Int(parameter)!)
    }

    var graphicsModes: ANSIGraphicsModes = []

    for parameter in parameters {
      switch parameter {
      case 0:
        graphicsModes.insert(.reset)
      case 1:
        graphicsModes.insert(.bold)
      case 2:
        graphicsModes.insert(.dim)
      case 3:
        graphicsModes.insert(.italic)
      case 4:
        graphicsModes.insert(.underline)
      case 5:
        graphicsModes.insert(.blinking)
      case 7:
        graphicsModes.insert(.inverse)
      case 8:
        graphicsModes.insert(.invisible)
      case 9:
        graphicsModes.insert(.strikethrough)
      case 30:
        graphicsModes.insert(.foreground(Color.black))
      case 31:
        graphicsModes.insert(.foreground(Color.red))
      case 32:
        graphicsModes.insert(.foreground(Color.green))
      case 33:
        graphicsModes.insert(.foreground(Color.yellow))
      case 34:
        graphicsModes.insert(.foreground(Color.blue))
      case 35:
        graphicsModes.insert(.foreground(Color(red: 1.0, green: 0.0, blue: 1.0)))
      case 36:
        graphicsModes.insert(.foreground(Color(red: 0.0, green: 1.0, blue: 1.0)))
      case 37:
        graphicsModes.insert(.foreground(Color.white))
      case 90:
        graphicsModes.insert(.foreground(Color.gray))
      case 91:
        graphicsModes.insert(.foreground(Color(red: 1.0, green: 0.5, blue: 0.5)))
      case 92:
        graphicsModes.insert(.foreground(Color(red: 0.5, green: 1.0, blue: 0.5)))
      case 93:
        graphicsModes.insert(.foreground(Color(red: 1.0, green: 1.0, blue: 0.5)))
      case 94:
        graphicsModes.insert(.foreground(Color(red: 0.5, green: 0.5, blue: 1.0)))
      case 95:
        graphicsModes.insert(.foreground(Color(red: 1.0, green: 0.5, blue: 1.0)))
      case 96:
        graphicsModes.insert(.foreground(Color(red: 0.5, green: 1.0, blue: 1.0)))
      case 97:
        graphicsModes.insert(.foreground(Color.white))
      case 40:
        graphicsModes.insert(.background(Color.black))
      case 41:
        graphicsModes.insert(.background(Color.red))
      case 42:
        graphicsModes.insert(.background(Color.green))
      case 43:
        graphicsModes.insert(.background(Color.yellow))
      case 44:
        graphicsModes.insert(.background(Color.blue))
      case 45:
        graphicsModes.insert(.background(Color(red: 1.0, green: 0.0, blue: 1.0)))
      case 46:
        graphicsModes.insert(.background(Color(red: 0.0, green: 1.0, blue: 1.0)))
      case 47:
        graphicsModes.insert(.background(Color.white))
      case 100:
        graphicsModes.insert(.background(Color.gray))
      case 101:
        graphicsModes.insert(.background(Color(red: 1.0, green: 0.5, blue: 0.5)))
      case 102:
        graphicsModes.insert(.background(Color(red: 0.5, green: 1.0, blue: 0.5)))
      case 103:
        graphicsModes.insert(.background(Color(red: 1.0, green: 1.0, blue: 0.5)))
      case 104:
        graphicsModes.insert(.background(Color(red: 0.5, green: 0.5, blue: 1.0)))
      case 105:
        graphicsModes.insert(.background(Color(red: 1.0, green: 0.5, blue: 1.0)))
      case 106:
        graphicsModes.insert(.background(Color(red: 0.5, green: 1.0, blue: 1.0)))
      case 107:
        graphicsModes.insert(.background(Color.white))
      default:
        break
      }
    }

    let length = 1 + matches[0].count
    let escapeSequence = ANSIEscapeSequence.graphicsModes(graphicsModes)
    return (length, escapeSequence)
  }

  private static func parseEscapeSequence(
    _ text: Substring,
    _: inout Int
  ) -> BoundedEscapeSequence? {
    if let match = parseCursorControl(text) {
      return match
    } else if let match = parseEraseFunction(text) {
      return match
    } else if let match = parseScreenMode(text) {
      return match
    } else if let match = parseGraphicsModes(text) {
      return match
    }

    return nil
  }
}
