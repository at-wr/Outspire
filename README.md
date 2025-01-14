# Outspire
[![Build & Test](https://github.com/at-wr/Outspire/actions/workflows/build_test.yml/badge.svg)](https://github.com/at-wr/Outspire/actions/workflows/build_test.yml)

A simple iOS app for WFLA TSIMS built with SwiftUI.

## Overview

- Written in Swift with SwiftUI on Swift Playground
- Can be generally used

The current features include:

- Account Management
- Class Table
- Club Info
  - Category Picker
  - Member List (unstable)
- CAS Activity
  - Activity History View
  - Activity Management
  - Add New Activity Record
- Relay Encryption

Work in Progress (WIP):
- Today View
- Academic Score
- …

## Preview Screenshot

![Screenshot of adding Activity Record](https://i.imgur.com/29hYWLc.png)

## Third-party Usage and Disclaimer

Outspire is built upon the Web API of TSIMS, utilizing SwiftSoup for HTML parsing. [Easy-TSIMS](https://github.com/Computerization/Easy-TSIMS) by [Computerization](https://github.com/Computerization/) and [Joshua Chen](https://github.com/Josh-Cena) is used as an encrypted relay instance.

This application is a personal experiment for educational purposes. Any potential issues caused by misuse of this application are not the responsibility of the author of Outspire.

If you encounter any issues, feel free to create an issue or submit a pull request. And if you like this project, please give me a star! All kinds of contributions are welcome.

## Privacy Policy

Outspire does not collect any user data. All data will only be transmitted between the TSIMS server, the relay instance, if you’ve enabled the Relay Encryption, and your device.

## License

Outspire is licensed under the AGPLv3 license. The licenses for other open-source third-party packages are listed [here](./THIRD_PARTY_LICENSES).
