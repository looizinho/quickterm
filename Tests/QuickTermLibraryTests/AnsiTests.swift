import SwiftUI
import XCTest

@testable import QuickTermLibrary

func assertEscapeSequence(_ text: String, _ tree: ANSIParseTree, _ index: Int) -> BoundedEscapeSequence? {
  let offset = text.index(text.startIndex, offsetBy: index)
  XCTAssertNotNil(tree.controlCharacters[offset])
  XCTAssertNotNil(tree.escapeSequences[offset])
  return tree.escapeSequences[offset]
}

final class ANSIParserTests: XCTestCase {
  func testParseColorCodes() {
    let simple = "Hello \u{001B}[31mred"
    let tree = ANSIParser.parse(simple)

    XCTAssertEqual(tree.controlCharacters.count, 1)
    XCTAssertEqual(tree.escapeSequences.count, 1)

    if let setColor = assertEscapeSequence(simple, tree, 6) {
      XCTAssertEqual(setColor.count, 5)
      if case let .graphicsModes(modes) = setColor.sequence {
        XCTAssertEqual(modes, [ANSIGraphicsMode.foreground(Color.red)])
      } else {
        XCTFail("Expected grapics modes")
      }
    }
  }

  func testParseVariousCodes() {
    let simple = "\u{001B}[10;10Hmovecursor\u{001B}[1;3;31msetgraphics"
    let tree = ANSIParser.parse(simple)

    XCTAssertEqual(tree.controlCharacters.count, 2)
    XCTAssertEqual(tree.escapeSequences.count, 2)

    if let moveCursor = assertEscapeSequence(simple, tree, 0) {
      XCTAssertEqual(moveCursor.count, 8)
      XCTAssertEqual(moveCursor.sequence, ANSIEscapeSequence.cursorControl)
    }

    if let setColor = assertEscapeSequence(simple, tree, 18) {
      XCTAssertEqual(setColor.count, 9)
      XCTAssertEqual(setColor.sequence, ANSIEscapeSequence.graphicsModes([.bold, .italic, .foreground(Color.red)]))
    }
  }

  func testDecoratedStringRendering() {
    // Test 1: Plain text without any formatting
    let plainText = "Hello World"
    let decorated1 = DecoratedString(fromString: plainText)
    XCTAssertEqual(decorated1.value, plainText)
    XCTAssertNotNil(decorated1.text)

    // Test 2: Red text with reset
    let redText = "Normal \u{001B}[31mRed\u{001B}[0m Normal"
    let decorated2 = DecoratedString(fromString: redText)
    XCTAssertEqual(decorated2.value, redText)
    XCTAssertNotNil(decorated2.text)

    // Test 3: Bold text
    let boldText = "\u{001B}[1mBold\u{001B}[0m Normal"
    let decorated3 = DecoratedString(fromString: boldText)
    XCTAssertEqual(decorated3.value, boldText)
    XCTAssertNotNil(decorated3.text)

    // Test 4: Multiple colors
    let multiColor = "\u{001B}[32mGreen\u{001B}[0m \u{001B}[34mBlue\u{001B}[0m"
    let decorated4 = DecoratedString(fromString: multiColor)
    XCTAssertEqual(decorated4.value, multiColor)
    XCTAssertNotNil(decorated4.text)

    // Test 5: All standard ANSI colors
    let allColors = "\u{001B}[30m30\u{001B}[31m31\u{001B}[32m32\u{001B}[33m33\u{001B}[34m34\u{001B}[35m35\u{001B}[36m36\u{001B}[37m37\u{001B}[0m"
    let decorated5 = DecoratedString(fromString: allColors)
    XCTAssertEqual(decorated5.value, allColors)
    XCTAssertNotNil(decorated5.text)

    // Test 6: Bright colors (90-97)
    let brightColors = "\u{001B}[90m90\u{001B}[91m91\u{001B}[92m92\u{001B}[93m93\u{001B}[94m94\u{001B}[95m95\u{001B}[96m96\u{001B}[97m97\u{001B}[0m"
    let decorated6 = DecoratedString(fromString: brightColors)
    XCTAssertEqual(decorated6.value, brightColors)
    XCTAssertNotNil(decorated6.text)

    // Test 7: Combined formatting (bold + color)
    let combined = "\u{001B}[1;31mBold Red\u{001B}[0m"
    let decorated7 = DecoratedString(fromString: combined)
    XCTAssertEqual(decorated7.value, combined)
    XCTAssertNotNil(decorated7.text)
  }
}
