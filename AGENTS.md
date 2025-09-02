# Repository Guidelines

## Project Structure & Module Organization
- `Outspire/`: main app code (SwiftUI). Domain folders under `Core/` (Models, Services, Utils, Views), `Features/` (feature-specific Views/ViewModels), and `UI/` (shared Components, Extensions). Assets in `Assets.xcassets` and `Resources/`.
- `OutspireWidget/`: Widget extension (Live Activity, timelines, data service).
- `OutspireTests/` and `OutspireUITests/`: unit and UI tests.
- `Outspire.xcodeproj/`: Xcode project; CI config in `.github/workflows/`.
- Local config: copy `Outspire/Configurations.local.swift.example` to `Outspire/Configurations.local.swift` and set `llmApiKey`/`llmBaseURL` (do not commit secrets).

## Build, Test, and Development Commands
- Open in Xcode: `open Outspire.xcodeproj` (preferred for local dev, run on iOS Simulator).
- CLI build: `xcodebuild -project Outspire.xcodeproj -scheme Outspire -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build`.
- Run unit/UI tests: `xcodebuild test -project Outspire.xcodeproj -scheme Outspire -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`.
- List simulators if needed: `xcrun simctl list devices`.

## Coding Style & Naming Conventions
- Swift + SwiftUI; 4‑space indentation, spaces over tabs; keep lines readable (~120 chars).
- Types `UpperCamelCase`; methods/vars `lowerCamelCase`; constants `lowerCamelCase` with `let`.
- Prefer structs, immutability, `guard` for early exits, avoid force unwraps.
- Organize with `// MARK:` and feature folders under `Outspire/Features/<Area>/`.

## Testing Guidelines
- Framework: XCTest. Place unit tests in `OutspireTests/*Tests.swift`, UI tests in `OutspireUITests/*UITests*.swift`.
- Name tests descriptively: `function_underTest_expectedBehavior`.
- Aim for coverage of Services (e.g., `Core/Services/*`) and view models. Run via Xcode or the `xcodebuild test` command above.

## Commit & Pull Request Guidelines
- Commit style: Conventional Commits (e.g., `feat(Cache): classtable caching`, `fix(Notifications): registration`). Group related changes; keep messages concise.
- PRs: include clear description, linked issues, steps to test, and screenshots for UI changes. Note any config/env requirements (e.g., `Configurations.local.swift`). Ensure CI passes.

## Documentation & Apple MCP Tool
- Use the Apple MCP documentation tool for Apple-related work: search official docs, WWDC sessions, API availability, and related/modern alternatives.
- Policy: whenever you’re unsure about an Apple API (behavior, availability, best practices) or when documentation could help, use the MCP tool first.
- Common lookups: SwiftUI availability across iOS/macOS, widget/Live Activity best practices, deprecation replacements, and sample code references.
- Prefer MCP-sourced answers over generic web results to ensure accuracy and correct OS-version context.

## Security & Configuration Tips
- Never commit secrets. Use `Configurations.local.swift` for local keys and app settings. Review `*.entitlements` and App Group usage (`group.dev.wrye.Outspire`) when changing widgets/Live Activities.
