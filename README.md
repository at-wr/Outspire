<img align="left" width="60" height="60" src="https://raw.githubusercontent.com/at-wr/Outspire/refs/heads/main/Icon.png" alt="Outspire App Icon">

# Outspire
[![Xcode Build & Test](https://github.com/at-wr/Outspire/actions/workflows/build_test.yml/badge.svg)](https://github.com/at-wr/Outspire/actions/workflows/build_test.yml)

Your all-in-one WFLA campus companian. It's an iOS app for WFLA TSIMS, which is also compatible with macOS.

## Overview

- Written in Swift with SwiftUI
- Migrated to Xcode, from Swift Playgrounds
- Can be daily used

## Features

- Today View
	- [x] Upcoming & Current Class Countdown
- Network / Account
	- [x] Account
	- [x] Relay Encryption
- Clubs / CAS
	- [x] Club Info
	- [x] Club Member List (available with account)
	- [x] Activity Record
	- [x] Category Picker
	- [x] Activity History View
	- [x] Activity Management
	- [x] New Activity Record
- Academic
	- [x] Academic Score
	- [x] Class Countdown
	- [x] Classtable
- School Data
	- [x] Weekly Arrangements
	- [x] Lunch Menus
- [ ] …

## URL Scheme Support

Outspire supports URL schemes for deep linking into different parts of the app. You can use these to quickly access specific views or content.

### URL Format
`outspire://<path>/<parameter>`

### Supported Paths

- **Today View**: `outspire://today`
- **Class Table**: `outspire://classtable`
- **Club Information**: `outspire://club/<clubId>`
- **Add Activity**: `outspire://addactivity/<clubId>`

### Examples

- Open the app to the Today view: `outspire://today`
- Open a specific club's information: `outspire://club/89`
- Create a new activity record for a specific club: `outspire://addactivity/89`

Note: You must be signed in to access most of these features via URL schemes.

## Terms of Service

Outspire is built on the Web API of TSIMS, utilizing SwiftSoup for HTML parsing. 

This application is a personal experiment for educational purposes. Any potential issues caused by misuse of this application are not the responsibility of the author of Outspire.

When you begin using the app, you agree not to use the App outside of its intended usage.

If you encounter any issues, please create an issue or submit a pull request. If you like this project, please consider giving it a star! All kinds of contributions are welcome.

## Privacy Policy

Outspire doesn't collect any user data. All data will be transmitted between the data source, the relay instance, and your device if you’ve enabled Relay Encryption. Relay instance does not collect or store any user data.

## License

Outspire is licensed under the MIT license. The licenses for other open-source third-party packages are listed [here](./THIRD_PARTY_LICENSES).
