import XCTest
@testable import ClaudeBarCore

final class UsageAggregatorTests: XCTestCase {

    let limits = UsageLimits(sessionOutputTokenLimit: 10_000, weeklyOutputTokenLimit: 70_000)

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

    // MARK: - Weekly window (last 7 days)

    func test_weekly_includesRecordsWithinLast7Days() {
        let records = [
            makeRecord(daysAgo: 6, outputTokens: 3000),
            makeRecord(daysAgo: 8, outputTokens: 9999), // outside
        ]

        let stats = UsageAggregator.aggregate(records: records, now: Date(), limits: limits)

        XCTAssertEqual(stats.weekly.tokensUsed, 3000)
    }

    func test_weekly_percentageIsProportionalToLimit() {
        let records = [makeRecord(daysAgo: 3, outputTokens: 35_000)]

        let stats = UsageAggregator.aggregate(records: records, now: Date(), limits: limits)

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
            inputTokens: 0,
            outputTokens: outputTokens,
            cacheReadTokens: 0,
            cacheCreationTokens: 0
        )
    }
}
