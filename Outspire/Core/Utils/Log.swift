import Foundation
import OSLog

enum Log {
    private static let subsystem = "dev.wrye.Outspire"

    static let app = Logger(subsystem: subsystem, category: "App")
    static let net = Logger(subsystem: subsystem, category: "Network")
    static let auth = Logger(subsystem: subsystem, category: "Auth")
    static let widget = Logger(subsystem: subsystem, category: "Widget")
}

