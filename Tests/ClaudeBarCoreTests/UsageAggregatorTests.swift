import XCTest
@testable import ClaudeBarCore

final class UsageAggregatorTests: XCTestCase {

    let limits = UsageLimits(sessionTokenLimit: 10_000, weeklyTokenLimit: 70_000)

    // MARK: - Session window (last 5 hours)

    func test_session_includesRecordsWithinLast5Hours() {
        let records = [
            makeRecord(hoursAgo: 3, outputTokens: 1000),
            makeRecord(hoursAgo: 6, outputTokens: 9999), // outside
        ]

        let stats = UsageAggregator.aggregate(records: records, now: Date(), limits: limits)

        XCTAssertEqual(stats.session.tokensUsed, 1000)
    }

    func test_session_percentageIsProportionalToLimit() {
        let records = [makeRecord(hoursAgo: 1, outputTokens: 5000)]

        let stats = UsageAggregator.aggregate(records: records, now: Date(), limits: limits)

        XCTAssertEqual(stats.session.percentage, 50.0, accuracy: 0.01)
    }

    func test_session_percentageCapsAt100() {
        let records = [makeRecord(hoursAgo: 1, outputTokens: 50_000)]

        let stats = UsageAggregator.aggregate(records: records, now: Date(), limits: limits)

        XCTAssertEqual(stats.session.percentage, 100.0)
    }

    func test_session_emptyRecordsGivesZeroPercent() {
        let stats = UsageAggregator.aggregate(records: [], now: Date(), limits: limits)

        XCTAssertEqual(stats.session.percentage, 0.0)
        XCTAssertEqual(stats.session.tokensUsed, 0)
    }

    // MARK: - Weekly window (Mon 11 AM fixed reset)
    // Use a fixed "now" of Wednesday 2026-02-04 15:00 UTC so the last Mon 11 AM
    // is deterministically 2026-02-02 11:00 local = ~50h before now.

    /// Wednesday 2026-02-04 15:00:00 UTC
    var fixedNow: Date {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 2; comps.day = 4
        comps.hour = 15; comps.minute = 0; comps.second = 0
        comps.timeZone = TimeZone(identifier: "UTC")
        return Calendar.current.date(from: comps)!
    }

    func test_weekly_includesRecordsSinceLastMonday11AM() {
        // Use fixed now. Records inside/outside the Mon-11AM window.
        let inside  = makeRecordAt(fixedNow.addingTimeInterval(-24 * 3600), outputTokens: 3000)   // Tuesday
        let outside = makeRecordAt(fixedNow.addingTimeInterval(-8 * 24 * 3600), outputTokens: 9999) // last week

        let stats = UsageAggregator.aggregate(records: [inside, outside], now: fixedNow, limits: limits)

        XCTAssertEqual(stats.weekly.tokensUsed, 3000)
    }

    func test_weekly_percentageIsProportionalToLimit() {
        let record = makeRecordAt(fixedNow.addingTimeInterval(-24 * 3600), outputTokens: 35_000)

        let stats = UsageAggregator.aggregate(records: [record], now: fixedNow, limits: limits)

        XCTAssertEqual(stats.weekly.percentage, 50.0, accuracy: 0.01)
    }

    // MARK: - Monthly cost

    func test_monthlyCost_includesOnlyCurrentMonthRecords() {
        let now = Date()
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        // Inside month — 1M output tokens = $15.00
        let inRecord = MessageRecord(
            timestamp: startOfMonth.addingTimeInterval(3600),
            model: "claude-sonnet-4-6",
            inputTokens: 0, outputTokens: 1_000_000,
            cacheReadTokens: 0, cacheCreationTokens: 0
        )
        // Before month — should be excluded
        let outRecord = MessageRecord(
            timestamp: startOfMonth.addingTimeInterval(-3600),
            model: "claude-sonnet-4-6",
            inputTokens: 0, outputTokens: 1_000_000,
            cacheReadTokens: 0, cacheCreationTokens: 0
        )

        let stats = UsageAggregator.aggregate(
            records: [inRecord, outRecord], now: now, limits: limits
        )

        XCTAssertEqual(stats.monthlyCostUSD, 15.0, accuracy: 0.01)
    }

    // MARK: - Helpers

    func makeRecord(hoursAgo: Double = 0, daysAgo: Double = 0, outputTokens: Int) -> MessageRecord {
        MessageRecord(
            timestamp: Date().addingTimeInterval(-(hoursAgo * 3600 + daysAgo * 86400)),
            model: "claude-sonnet-4-6",
            inputTokens: 0, outputTokens: outputTokens,
            cacheReadTokens: 0, cacheCreationTokens: 0
        )
    }

    func makeRecordAt(_ date: Date, outputTokens: Int) -> MessageRecord {
        MessageRecord(
            timestamp: date,
            model: "claude-sonnet-4-6",
            inputTokens: 0, outputTokens: outputTokens,
            cacheReadTokens: 0, cacheCreationTokens: 0
        )
    }
}
