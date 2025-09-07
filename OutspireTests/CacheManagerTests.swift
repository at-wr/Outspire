import XCTest
@testable import Outspire

final class CacheManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        clearAll()
    }

    override func tearDown() {
        clearAll()
        super.tearDown()
    }

    private func clearAll() {
        let ud = UserDefaults.standard
        for key in ud.dictionaryRepresentation().keys {
            if key.hasPrefix("cached") || key.hasSuffix("timestamp") || key.contains("Cache") || key.contains("selected") || key.contains("years") || key.contains("terms") {
                ud.removeObject(forKey: key)
            }
        }
    }

    func test_clearClasstableCache_removesExpectedKeys() {
        let ud = UserDefaults.standard
        ud.set(Data([0x01]), forKey: "cachedYears")
        ud.set(123.0, forKey: "yearsCacheTimestamp")
        ud.set("2024", forKey: "selectedYearId")
        ud.set(Data([0x02]), forKey: "cachedTimetable-2024")
        ud.set(123.0, forKey: "timetableCacheTimestamp-2024")

        CacheManager.clearClasstableCache()

        XCTAssertNil(ud.data(forKey: "cachedYears"))
        XCTAssertEqual(ud.double(forKey: "yearsCacheTimestamp"), 0)
        XCTAssertNil(ud.string(forKey: "selectedYearId"))
        XCTAssertNil(ud.data(forKey: "cachedTimetable-2024"))
        XCTAssertEqual(ud.double(forKey: "timetableCacheTimestamp-2024"), 0)
    }

    func test_cleanupOutdatedCache_removesExpired() {
        let ud = UserDefaults.standard
        // Set timestamps far in the past
        ud.set(0.0, forKey: "yearsCacheTimestamp")
        ud.set(0.0, forKey: "termsCacheTimestamp")
        ud.set(0.0, forKey: "clubActivitiesCacheTimestamp")
        ud.set(0.0, forKey: "cachedSchoolArrangements-timestamp")
        ud.set(Data([0xFF]), forKey: "cachedYears")
        ud.set(Data([0xEE]), forKey: "cachedTerms")
        ud.set(Data([0xDD]), forKey: "cachedClubGroups")
        ud.set(Data([0xCC]), forKey: "cachedSchoolArrangements")
        ud.set(0.0, forKey: "timetableCacheTimestamp-2024")
        ud.set(Data([0xAA]), forKey: "cachedTimetable-2024")
        ud.set(0.0, forKey: "scoresCacheTimestamp-2024S1")
        ud.set(Data([0xBB]), forKey: "cachedScores-2024S1")
        ud.set(0.0, forKey: "cachedActivities-123-timestamp")
        ud.set(Data([0x11]), forKey: "cachedActivities-123")

        CacheManager.cleanupOutdatedCache()

        XCTAssertNil(ud.data(forKey: "cachedYears"))
        XCTAssertNil(ud.data(forKey: "cachedTerms"))
        XCTAssertNil(ud.data(forKey: "cachedClubGroups"))
        XCTAssertNil(ud.data(forKey: "cachedSchoolArrangements"))
        XCTAssertNil(ud.data(forKey: "cachedTimetable-2024"))
        XCTAssertNil(ud.data(forKey: "cachedScores-2024S1"))
        XCTAssertNil(ud.data(forKey: "cachedActivities-123"))
    }

    func test_getOutdatedCacheCount_countsExpired() {
        let ud = UserDefaults.standard
        ud.set(0.0, forKey: "yearsCacheTimestamp")
        ud.set(0.0, forKey: "termsCacheTimestamp")
        ud.set(0.0, forKey: "clubActivitiesCacheTimestamp")
        ud.set(0.0, forKey: "cachedSchoolArrangements-timestamp")
        ud.set(0.0, forKey: "timetableCacheTimestamp-2024")
        ud.set(0.0, forKey: "scoresCacheTimestamp-2024S1")

        let count = CacheManager.getOutdatedCacheCount()
        XCTAssertGreaterThanOrEqual(count, 4)
    }
}

