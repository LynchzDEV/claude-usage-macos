import Foundation

public struct UsageAggregator {

    /// Claude resets weekly limits on Monday at 11:00 AM.
    static let weeklyResetWeekday = 2  // Monday (1=Sun … 7=Sat)
    static let weeklyResetHour    = 11

    public static func aggregate(
        records: [MessageRecord],
        now: Date = .init(),
        limits: UsageLimits = .defaults
    ) -> UsageStats {
        let sessionCutoff = now.addingTimeInterval(-5 * 3600)
        let weeklyCutoff  = weeklyWindowStart(now: now)
        let monthStart    = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: now)
        )!

        let sessionRecords = records.filter { $0.timestamp >= sessionCutoff }
        let weeklyRecords  = records.filter { $0.timestamp >= weeklyCutoff }
        let monthlyRecords = records.filter { $0.timestamp >= monthStart }

        // Claude rate-limits on output tokens only
        let sessionTokens = sessionRecords.reduce(0) { $0 + $1.outputTokens }
        let weeklyTokens  = weeklyRecords.reduce(0)  { $0 + $1.outputTokens }

        // Session window end: oldest record + 5h (rolling)
        let sessionWindowEnd: Date = {
            if let oldest = sessionRecords.min(by: { $0.timestamp < $1.timestamp }) {
                return oldest.timestamp.addingTimeInterval(5 * 3600)
            }
            return now.addingTimeInterval(5 * 3600)
        }()

        // Weekly window end: next Monday 11 AM
        let weeklyWindowEnd = Calendar.current.date(
            byAdding: .weekOfYear, value: 1, to: weeklyCutoff
        )!

        return UsageStats(
            session: WindowStats(
                tokensUsed: sessionTokens,
                percentage: min(Double(sessionTokens) / Double(limits.sessionTokenLimit) * 100, 100),
                windowEnd: sessionWindowEnd
            ),
            weekly: WindowStats(
                tokensUsed: weeklyTokens,
                percentage: min(Double(weeklyTokens) / Double(limits.weeklyTokenLimit) * 100, 100),
                windowEnd: weeklyWindowEnd
            ),
            monthlyCostUSD: CostCalculator.estimate(records: monthlyRecords),
            lastUpdated: now
        )
    }

    /// Most recent Monday at 11:00 AM, at or before `now`.
    private static func weeklyWindowStart(now: Date) -> Date {
        var cal = Calendar.current
        cal.firstWeekday = weeklyResetWeekday

        var comps = cal.dateComponents(
            [.yearForWeekOfYear, .weekOfYear, .weekday, .hour, .minute, .second], from: now
        )
        comps.weekday = weeklyResetWeekday
        comps.hour    = weeklyResetHour
        comps.minute  = 0
        comps.second  = 0

        guard var candidate = cal.date(from: comps) else {
            return now.addingTimeInterval(-7 * 24 * 3600)
        }
        if candidate > now {
            candidate = cal.date(byAdding: .weekOfYear, value: -1, to: candidate) ?? candidate
        }
        return candidate
    }
}
