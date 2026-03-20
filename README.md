# Outspire

[![Xcode Build & Test](https://github.com/Computerization/Outspire/actions/workflows/build_test.yml/badge.svg)](https://github.com/Computerization/Outspire/actions/workflows/build_test.yml)
[![App Store](https://img.shields.io/badge/App_Store-0D96F6?logo=app-store&logoColor=white)](https://apps.apple.com/us/app/outspire/id6743143348)

Your all-in-one WFLA campus companion. A native iOS & macOS app for WFLA TSIMS, built with Swift and SwiftUI.

## Features

### Today Dashboard
- Current & upcoming class countdown with live progress ring
- School day summary (assembly, arrival, lunch times)
- Quick links to clubs, dining, activities, and reflections
- Weather integration and location-aware travel time
- Dynamic gradient backgrounds that adapt to your schedule context

### Academics
- Full interactive classtable with day-by-day navigation
- Academic score viewer
- Live Activity support for class countdowns on Lock Screen & Dynamic Island
- Home Screen widgets for at-a-glance schedule info

### CAS (Creativity, Activity, Service)
- Browse club information and member lists
- Log and manage activity records with category tagging
- Write CAS reflections with learning outcome tracking
- Activity history with search and filtering

### School Life
- Weekly school arrangements (PDF viewer)
- Daily lunch menus

### Platform Integration
- iOS 26 Liquid Glass design with adaptive materials
- Home Screen widgets (WidgetKit)
- Live Activities for class countdowns
- Deep linking via URL schemes and universal links
- Mac Catalyst support

## Tech Stack

- **UI**: SwiftUI with custom design token system, SF Symbol effects, Liquid Glass (iOS 26+)
- **Architecture**: MVVM with shared services (`AuthServiceV2`, `SessionService`, `ClasstableViewModel`)
- **Networking**: URLSession with HTML parsing via SwiftSoup
- **Dependencies**: SwiftSoup, swiftui-toasts, ColorfulX, SwiftOpenAI
- **CI/CD**: GitHub Actions (build, test, lint, unsigned IPA artifacts)

## URL Schemes

```
outspire://today              → Today view
outspire://classtable         → Class table
outspire://club/<clubId>      → Club information
outspire://addactivity/<id>   → New activity record
```

Universal links are also supported via `https://outspire.wrye.dev/app/...`.

## Building

Requires Xcode 16+ and iOS 17+ deployment target.

```bash
xcodebuild -project Outspire.xcodeproj -scheme Outspire \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Terms of Service

Outspire is built on the Web API of TSIMS, utilizing SwiftSoup for HTML parsing. This application is a personal experiment for educational purposes. Any potential issues caused by misuse of this application are not the responsibility of the author.

When you begin using the app, you agree not to use the App outside of its intended usage. If you encounter any issues, please create an issue or submit a pull request.

## Privacy Policy

Outspire doesn't collect any user data. All data is transmitted between the data source, the relay instance, and your device. The relay instance does not collect or store any user data.

## License

MIT License. Third-party licenses are listed in [Outspire/Resources/ThirdPartyLicenses.txt](Outspire/Resources/ThirdPartyLicenses.txt).
