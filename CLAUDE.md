# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Outspire is a Swift/SwiftUI app (iOS + Mac Catalyst) with a WidgetKit extension and Live Activities support.

Key targets (from `xcodebuild -list`):
- `Outspire` (main app)
- `OutspireWidgetExtension` (widgets + Live Activity widget)
- `OutspireTests`, `OutspireUITests`

Third-party SwiftPM deps are integrated via the Xcode project (see `Outspire.xcodeproj/project.pbxproj`):
- `SwiftSoup` (HTML parsing)
- `swiftui-toasts` (toasts)
- `ColorfulX` (color/gradient utilities)
- `SwiftOpenAI`

## Common commands

### List schemes/targets

```bash
xcodebuild -list -project Outspire.xcodeproj
```

### Build & test (CI equivalent)

CI runs SwiftFormat (lint), SwiftLint, then `xcodebuild clean test` on an iOS Simulator:

```bash
# formatting (lint only)
swiftformat --lint .

# lint
swiftlint

# build + test (simulator)
xcodebuild \
  -project Outspire.xcodeproj \
  -scheme "Outspire" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -enableCodeCoverage YES \
  clean test
```

Reference: `.github/workflows/build_test.yml`.

### Build unsigned IPA (CI artifact)

```bash
xcodebuild \
  -project Outspire.xcodeproj \
  -scheme "Outspire" \
  PRODUCT_BUNDLE_IDENTIFIER="dev.wrye.Outspire" \
  -sdk iphoneos \
  -destination 'platform=iOS' \
  -configuration Release \
  archive \
  -archivePath ./build/Outspire.xcarchive \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

mkdir Payload
cp -R ./build/Outspire.xcarchive/Products/Applications/*.app Payload/
zip -0 -y -r Outspire.ipa Payload
```

Reference: `.github/workflows/ios_artifact.yml`.

### Run a single test

Use `-only-testing` with `xcodebuild test`:

```bash
xcodebuild \
  -project Outspire.xcodeproj \
  -scheme "Outspire" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:OutspireTests/<TestClassName>/<testMethodName> \
  test
```

(Adjust the test identifier to match the test bundle/class names.)

## Code architecture (big picture)

### App entrypoint + global services

- `Outspire/OutspireApp.swift` defines `@main` (`OutspireApp`) and wires up app-wide `EnvironmentObject`s:
  - `SessionService.shared` (legacy auth/session)
  - `AuthServiceV2.shared` (new TSIMS auth used throughout UI)
  - `LocationManager.shared`, `RegionChecker.shared`, `NotificationManager.shared`
  - `ConnectivityManager.shared` (connectivity monitoring + alerts)
  - `GradientManager` (dynamic gradients)
  - `URLSchemeHandler.shared` (deep links + universal links)
  - `WidgetDataManager` (writes shared widget state into the App Group)

It also:
- registers Live Activities (iOS only) via `LiveActivityRegistration.registerLiveActivities()`
- handles deep links via `.onOpenURL` and universal links via `.onContinueUserActivity`
- mirrors auth/holiday/timetable state into the widget App Group (`group.dev.wrye.Outspire`)

### Deep linking

- `Outspire/Core/Services/URLSchemeHandler.swift` owns navigation triggers:
  - scheme: `outspire://...`
  - universal links: `https://outspire.wrye.dev/app/...` converted into scheme URLs

The handler publishes flags like `navigateToToday`, `navigateToClassTable`, `navigateToClub`, etc., which UI can observe to drive navigation.

### Today screen + Live Activity integration

- `Outspire/Features/Main/Views/TodayView.swift` is a central dashboard screen.
  - pulls schedule data via `ClasstableViewModel`
  - checks auth primarily via `AuthServiceV2.shared.isAuthenticated`
  - optionally starts a Live Activity for the current/next class (iOS only) by calling into `ClassActivityManager.shared`

### Live Activities (in-app controller) vs widget UI

There are two layers:

1) **In-app Live Activity lifecycle** (start/update/end):
- `Outspire/Features/LiveActivity/ClassActivityManager.swift` wraps ActivityKit.
  - keys activities by `"<periodNumber>_<className>"`
  - schedules an automatic end task based on the last scheduled class end time

2) **Widget extension rendering** (Lock Screen + Dynamic Island):
- `OutspireWidget/LiveActivityWidget.swift` defines `OutspireWidgetLiveActivity: Widget` using `ActivityConfiguration`.
  - renders derived state via a `TimelineView` to refresh UI periodically
  - sets `.widgetURL(URL(string: "outspire://today"))` to deep link back into the app

### Widgets data flow (App Group)

- App side (`Outspire/OutspireApp.swift`): `WidgetDataManager` writes to `UserDefaults(suiteName: "group.dev.wrye.Outspire")`:
  - `isAuthenticated`
  - `widgetTimetableData` (JSON-encoded `[[String]]`)
  - holiday flags and end date

- Widget side (`OutspireWidget/WidgetDataService.swift`): `WidgetDataService` reads those values and computes widget timelines.

## Lint/format configuration

- SwiftLint config: `.swiftlint.yml` (includes `Outspire/` and `OutspireWidget/`)
- SwiftFormat config: `.swiftformat`

## Notes from CI

The GitHub Actions workflows are the authoritative reference for build/test/lint commands:
- `.github/workflows/build_test.yml`
- `.github/workflows/ios_artifact.yml`
