import Foundation

public struct UsageAggregator {

    public static func aggregate(
        records: [MessageRecord],
        now: Date = .init(),
        limits: UsageLimits = .defaults
    ) -> UsageStats {
        let sessionCutoff = now.addingTimeInterval(-5 * 3600)
        let weeklyCutoff  = now.addingTimeInterval(-7 * 24 * 3600)
        let monthStart    = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: now)
        )!

        let sessionRecords = records.filter { $0.timestamp >= sessionCutoff }
        let weeklyRecords  = records.filter { $0.timestamp >= weeklyCutoff }
        let monthlyRecords = records.filter { $0.timestamp >= monthStart }

        let sessionTokens = sessionRecords.reduce(0) { $0 + $1.outputTokens }
        let weeklyTokens  = weeklyRecords.reduce(0)  { $0 + $1.outputTokens }

        // Window end = oldest record in window + window duration (or now + full window if empty)
        let sessionWindowEnd: Date = {
            if let oldest = sessionRecords.min(by: { $0.timestamp < $1.timestamp }) {
                return oldest.timestamp.addingTimeInterval(5 * 3600)
            }
            return now.addingTimeInterval(5 * 3600)
        }()

        let weeklyWindowEnd: Date = {
            if let oldest = weeklyRecords.min(by: { $0.timestamp < $1.timestamp }) {
                return oldest.timestamp.addingTimeInterval(7 * 24 * 3600)
            }
            return now.addingTimeInterval(7 * 24 * 3600)
        }()

        return UsageStats(
            session: WindowStats(
                tokensUsed: sessionTokens,
                percentage: min(
                    Double(sessionTokens) / Double(limits.sessionOutputTokenLimit) * 100,
                    100
                ),
                windowEnd: sessionWindowEnd
            ),
            weekly: WindowStats(
                tokensUsed: weeklyTokens,
                percentage: min(
                    Double(weeklyTokens) / Double(limits.weeklyOutputTokenLimit) * 100,
                    100
                ),
                windowEnd: weeklyWindowEnd
            ),
            monthlyCostUSD: CostCalculator.estimate(records: monthlyRecords),
            lastUpdated: now
        )
    }
}
