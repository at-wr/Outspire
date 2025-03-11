<img align="left" width="60" height="60" src="https://raw.githubusercontent.com/at-wr/Outspire/refs/heads/main/Outspire.swiftpm/Assets.xcassets/AppIcon.appiconset/AppIcon.png" alt="Outspire App Icon">

# Outspire
[![Xcode Build & Test](https://github.com/at-wr/Outspire/actions/workflows/build_test.yml/badge.svg)](https://github.com/at-wr/Outspire/actions/workflows/build_test.yml)

A iOS app for WFLA TSIMS built with SwiftUI, which is also compatible with macOS.

## Overview

- Written in Swift with SwiftUI on Swift Playground
- Can be generally used

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
- [ ] …

### Planned

- Publish on TestFlight...
- Distribute to App Store...

## Preview Screenshot

![Screenshot of Outspire in Stage Manager](https://i.imgur.com/9HU9TSO.png)
![Screenshot of adding Activity Record](https://i.imgur.com/29hYWLc.png)

## Third-Party Usage and Disclaimer

Outspire is built on the Web API of TSIMS, utilizing SwiftSoup for HTML parsing. [Easy-TSIMS](https://github.com/Computerization/Easy-TSIMS) by [Computerization](https://github.com/Computerization/) and [Joshua Chen](https://github.com/Josh-Cena) is used as an encrypted relay instance.

This application is a personal experiment for educational purposes. Any potential issues caused by misuse of this application are not the responsibility of the author of Outspire.

If you encounter any issues, please create an issue or submit a pull request. If you like this project, please consider giving it a star! All kinds of contributions are welcome.

## Privacy Policy

Outspire doesn't collect any user data. Only data will be transmitted between the TSIMS server, the relay instance, and your device if you’ve enabled Relay Encryption.

## License

Outspire is licensed under the AGPLv3 license. The licenses for other open-source third-party packages are listed [here](./THIRD_PARTY_LICENSES).
