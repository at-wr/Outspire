// swift-tools-version: 5.9

// WARNING:
// This file is automatically generated.
// Do not edit it by hand because the contents will be replaced.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Outspire",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "Outspire",
            targets: ["AppModule"],
            displayVersion: "0.4",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .sparkle),
            accentColor: .presetColor(.cyan),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            capabilities: [
                .appTransportSecurity(configuration: .init(
                    exceptionDomains: [
                        .init(
                            domainName: "101.230.1.173",
                            includesSubdomains: true,
                            exceptionAllowsInsecureHTTPLoads: true
                        )
                    ]
                )),
                .faceID(purposeString: "Required to protect sensitive privacy, including academic score, etc.")
            ],
            appCategory: .education
        )
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", "2.7.6"..<"3.0.0"),
        .package(url: "https://github.com/sunghyun-k/swiftui-toasts.git", "0.2.0"..<"1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            dependencies: [
                .product(name: "SwiftSoup", package: "SwiftSoup"),
                .product(name: "Toasts", package: "swiftui-toasts")
            ],
            path: ".",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        )
    ]
)
