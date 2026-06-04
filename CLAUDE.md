# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**QuickTerm** is a native macOS 11+ application written in Swift 5 that provides a way to quickly run shell commands. It consists of a UI component, a command-line interface, and uses an XPC service for inter-process communication with a background daemon.

**Architecture**: arm64-only (Apple Silicon). The project is optimized for Apple Silicon and does not support Intel Macs (x86_64).

## Build, Test, and Lint Commands

All commands use the Makefile. Run `make help` to see all available commands.

### Common Development Commands

```sh
# Show all available make commands
make help

# Build the application (creates ./build/QuickTerm.app)
make build

# Run the UI application
make run

# Run the CLI with arguments
make run args="echo hello"

# Run all tests
make test

# Run only tests matching a pattern (replace path as needed)
swift test --build-path "build/test" --filter AnsiTests

# Lint Swift code (requires: brew install swiftformat)
make lint

# Format Swift code
make format

# Tail application logs
make logs

# Clean build artifacts
make clean
```

### Advanced Commands

```sh
# Sign the application for distribution (requires CODESIGN_IDENTITY)
make sign

# Package the application (creates ./distribution)
make package

# Build with sanitizers
SWIFT_FLAGS="--sanitize address" make build
```

### Setup

```sh
# Setup project for development (installs git hooks)
make setup
```

## Architecture

QuickTerm consists of four main Swift modules:

### **QuickTermShared**
- Shared types used between the UI and broker
- Key classes: `CommandConfiguration`, `CommandError`
- Key protocols: `BrokerProtocol`, `CommandExecutorProtocol`
- Contains serialization logic for XPC communication

### **QuickTermLibrary**
- ANSI escape sequence parsing and rendering (`Ansi.swift`)
- Spotlight-like UI components in `Spotlight/` subdirectory
- Cross-module utilities and extensions

### **QuickTerm** (Main UI Application)
- Entry point: `Sources/QuickTerm/main.swift`
- `AppDelegate.swift`: Core application lifecycle, global hotkey setup, menu bar UI
- `Config.swift`: YAML configuration file loading and watching
- `CommandExecutor.swift`: Bridges CLI arguments to command execution
- `TerminalSessionManager.swift`: Manages visible command windows
- Subdirectories:
  - `Views/` and `Components/`: SwiftUI UI components
  - `Controllers/`: View and window controllers
  - `Terminal/`: Process execution and terminal session logic
  - `Extensions/`: Swift extensions (Color, etc.)

### **QuickTermBroker** (XPC Service)
- Background daemon that the CLI communicates with
- Receives queued commands and delegates to the UI application
- Runs as an XPC service bundle (`.xpc` in the app bundle)

## Key Design Patterns

**Daemon + XPC Communication**: The app runs as a background daemon. The CLI communicates with it via NSXPCConnection to queue commands for the UI to display.

**File-Based Configuration**: Config is stored in `~/.config/quickterm/config.yml` and is watched for changes. The UI reloads automatically when the file changes.

**Global Hotkey**: Registered via the HotKey dependency; defaults to `⌥⌘T`. Configured in the YAML config file.

## Dependencies

- **swift-argument-parser**: CLI argument parsing
- **HotKey**: Global hotkey registration
- **Yams**: YAML parsing/generation for configuration

## Recent Work: ANSI Escape Sequence Support

The project is implementing ANSI escape sequence parsing for decorated terminal output rendering. Key files:

- `Sources/QuickTermLibrary/Ansi.swift`: Core parsing and rendering types
  - `ANSIParser`: Parses escape sequences into a tree
  - `DecoratedString`: Wraps a string with ANSI metadata for SwiftUI rendering
  - `ANSIGraphicsMode`: Enum for supported formatting (bold, colors, etc.)
- `Tests/QuickTermLibraryTests/AnsiTests.swift`: Comprehensive parsing tests

Recent commits show progression from basic support to regex-based parsing to a decorated rendering basis.

## Important Files

- `Package.swift`: Swift package manifest with target definitions
- `Makefile`: All build orchestration; uses `swift build` under the hood
- `.swiftformat`: Code formatting rules (SwiftFormat config)
- `SupportingFiles/`: App metadata (Info.plist, Entitlements.plist, resources)

## Configuration

The app configuration is stored at `~/.config/quickterm/config.yml`. Users can modify:

- Shell, timeout, animation, working directory, and other command execution settings
- Global hotkey binding (e.g., `option+command+t`)

The configuration is watched at runtime and reloads automatically in the UI.

## Testing Notes

Tests are located in `Tests/QuickTermLibraryTests/`. Run tests with `swift test` or filter specific test files/methods. The ANSI parser tests are comprehensive and test various escape sequence patterns.
