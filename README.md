# Outspire
[![Xcode Build & Test](https://github.com/at-wr/Outspire/actions/workflows/build_test.yml/badge.svg)](https://github.com/at-wr/Outspire/actions/workflows/build_test.yml)

A iOS app for WFLA TSIMS built with SwiftUI, which is also compatible with macOS.

## Overview

- Written in Swift with SwiftUI on Swift Playground
- Can be generally used

## Features

- [x] Account Management
- [x] Class Table
- [x] Club Info
- [x] Category Picker
- [x] Member List (unstable)
- [x] CAS Activity
- [x] Activity History View
- [x] Activity Management
- [x] Add New Activity Record
- [x] Relay Encryption
- [ ] Today View
- [ ] Academic Score
- [ ] …

## Preview Screenshot

![Screenshot of Outspire in Stage Manager](https://imgur.com/9HU9TSO)
![Screenshot of adding Activity Record](https://i.imgur.com/29hYWLc.png)

## Third-Party Usage and Disclaimer

Outspire is built on the Web API of TSIMS, utilizing SwiftSoup for HTML parsing. [Easy-TSIMS](https://github.com/Computerization/Easy-TSIMS) by [Computerization](https://github.com/Computerization/) and [Joshua Chen](https://github.com/Josh-Cena) is used as an encrypted relay instance.

This application is a personal experiment for educational purposes. Any potential issues caused by misuse of this application are not the responsibility of the author of Outspire.

If you encounter any issues, please create an issue or submit a pull request. If you like this project, please consider giving it a star! All kinds of contributions are welcome.

## Privacy Policy

Outspire doesn't collect any user data. Only data will be transmitted between the TSIMS server, the relay instance, and your device if you’ve enabled Relay Encryption.

## License

Outspire is licensed under the AGPLv3 license. The licenses for other open-source third-party packages are listed [here](./THIRD_PARTY_LICENSES).
