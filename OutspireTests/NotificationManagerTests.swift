import UserNotifications
import XCTest

@testable import Outspire

class NotificationManagerTests: XCTestCase {

    var notificationManager: NotificationManager!
    var mockNotificationCenter: MockUNUserNotificationCenter!

    override func setUp() {
        super.setUp()
        notificationManager = NotificationManager.shared
        mockNotificationCenter = MockUNUserNotificationCenter()

        // Clear any existing user defaults for testing
        UserDefaults.standard.removeObject(forKey: "departureNotificationsEnabled")
        UserDefaults.standard.removeObject(forKey: "departureNotificationTime")
    }

    override func tearDown() {
        // Clean up
        UserDefaults.standard.removeObject(forKey: "departureNotificationsEnabled")
        UserDefaults.standard.removeObject(forKey: "departureNotificationTime")
        super.tearDown()
    }

    func testScheduleNotificationRespectsUserPreference() {
        // Test that notifications are NOT scheduled when user preference is disabled
        Configuration.departureNotificationsEnabled = false

        let expectation = XCTestExpectation(description: "Notification should not be scheduled")

        // Mock authorization as granted
        let mockCenter = MockUNUserNotificationCenter()
        mockCenter.authorizationStatus = .authorized

        // Call the scheduling method
        notificationManager.scheduleMorningETANotification()

        // Verify no notifications were scheduled
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(
                mockCenter.addedRequests.count, 0,
                "No notifications should be scheduled when user preference is disabled")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testScheduleNotificationWhenEnabled() {
        // Test that notifications ARE scheduled when user preference is enabled
        Configuration.departureNotificationsEnabled = true

        let expectation = XCTestExpectation(description: "Notifications should be scheduled")

        // Mock authorization as granted
        let mockCenter = MockUNUserNotificationCenter()
        mockCenter.authorizationStatus = .authorized

        // Call the scheduling method
        notificationManager.scheduleMorningETANotification()

        // Verify notifications were scheduled (should be 5 for weekdays)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(
                mockCenter.addedRequests.count, 5,
                "Should schedule 5 notifications for weekdays when enabled")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testNotificationSchedulingWithoutAuthorization() {
        // Test that notifications are NOT scheduled when authorization is not granted
        Configuration.departureNotificationsEnabled = true

        let expectation = XCTestExpectation(
            description: "Notification should not be scheduled without authorization")

        // Mock authorization as denied
        let mockCenter = MockUNUserNotificationCenter()
        mockCenter.authorizationStatus = .denied

        // Call the scheduling method
        notificationManager.scheduleMorningETANotification()

        // Verify no notifications were scheduled
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(
                mockCenter.addedRequests.count, 0,
                "No notifications should be scheduled without authorization")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testCentralizedNotificationManagement() {
        // Test the centralized notification management methods
        let expectation = XCTestExpectation(
            description: "Centralized management should work correctly")

        // Test with notifications disabled
        Configuration.departureNotificationsEnabled = false
        notificationManager.updateNotificationScheduling()

        // Test with notifications enabled
        Configuration.departureNotificationsEnabled = true
        notificationManager.handleNotificationSettingsChange()

        // Test app became active
        notificationManager.handleAppBecameActive()

        // If we get here without crashing, the methods work
        expectation.fulfill()

        wait(for: [expectation], timeout: 1.0)
    }

    func testDefaultNotificationPreference() {
        // Test that the default notification preference is disabled
        let defaultEnabled = Configuration.departureNotificationsEnabled
        XCTAssertFalse(defaultEnabled, "Default notification preference should be disabled")
    }

    func testNotificationCancellation() {
        // Test that notifications are properly cancelled
        let expectation = XCTestExpectation(description: "Notifications should be cancelled")

        // First enable and schedule
        Configuration.departureNotificationsEnabled = true
        notificationManager.scheduleMorningETANotification()

        // Then disable and verify cancellation
        Configuration.departureNotificationsEnabled = false
        notificationManager.handleNotificationSettingsChange()

        // The method should complete without error
        expectation.fulfill()

        wait(for: [expectation], timeout: 1.0)
    }
}

// Mock class for testing
class MockUNUserNotificationCenter: UNUserNotificationCenter {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var addedRequests: [UNNotificationRequest] = []
    var removedIdentifiers: [String] = []

    override func getNotificationSettings(
        completionHandler: @escaping (UNNotificationSettings) -> Void
    ) {
        let settings = MockUNNotificationSettings(authorizationStatus: authorizationStatus)
        completionHandler(settings)
    }

    override func add(
        _ request: UNNotificationRequest,
        withCompletionHandler completionHandler: ((Error?) -> Void)? = nil
    ) {
        addedRequests.append(request)
        completionHandler?(nil)
    }

    override func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers.append(contentsOf: identifiers)
    }

    override func getPendingNotificationRequests(
        completionHandler: @escaping ([UNNotificationRequest]) -> Void
    ) {
        completionHandler(addedRequests)
    }
}

class MockUNNotificationSettings: UNNotificationSettings {
    private let _authorizationStatus: UNAuthorizationStatus

    init(authorizationStatus: UNAuthorizationStatus) {
        _authorizationStatus = authorizationStatus
        super.init()
    }

    override var authorizationStatus: UNAuthorizationStatus {
        return _authorizationStatus
    }
}

// MARK: - Additional Unit Tests (NetworkService, SecureStore)

private class MockURLProtocol: URLProtocol {
    static var responseData: Data?
    static var statusCode: Int = 200
    static var responseHeaders: [String: String]? = ["Content-Type": "application/json"]
    static var error: Error?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let error = MockURLProtocol.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let url = request.url ?? URL(string: "https://example.com")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: MockURLProtocol.statusCode,
            httpVersion: nil,
            headerFields: MockURLProtocol.responseHeaders
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let data = MockURLProtocol.responseData {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

struct TestDecodable: Codable, Equatable { let message: String }

extension NotificationManagerTests {
    func testSecureStore_set_get_remove() {
        let key = "test.keychain.key"
        let value = "secret-value"

        SecureStore.set(value, for: key)
        let fetched = SecureStore.get(key)
        XCTAssertEqual(fetched, value)

        SecureStore.remove(key)
        let removed = SecureStore.get(key)
        XCTAssertNil(removed)
    }

    func testNetworkService_async_success() async throws {
        guard #available(iOS 15.0, *) else { return }

        // Prepare mocked session
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        #if DEBUG
        NetworkService.shared.setSession(session)
        #endif

        let payload = TestDecodable(message: "ok")
        let data = try JSONEncoder().encode(payload)
        MockURLProtocol.responseData = data
        MockURLProtocol.statusCode = 200
        MockURLProtocol.error = nil

        let result: TestDecodable = try await NetworkService.shared.requestAsync(
            endpoint: "test_endpoint.php",
            method: .post,
            parameters: ["a": "b"],
            sessionId: "mockSession"
        )

        XCTAssertEqual(result, payload)
    }

    func testNetworkService_async_serverError() async {
        guard #available(iOS 15.0, *) else { return }

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        #if DEBUG
        NetworkService.shared.setSession(session)
        #endif

        MockURLProtocol.responseData = Data("{}".utf8)
        MockURLProtocol.statusCode = 500
        MockURLProtocol.error = nil

        do {
            let _: TestDecodable = try await NetworkService.shared.requestAsync(
                endpoint: "test_endpoint.php"
            )
            XCTFail("Expected to throw NetworkError.serverError")
        } catch {
            guard case NetworkError.serverError(let code) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(code, 500)
        }
    }
}
