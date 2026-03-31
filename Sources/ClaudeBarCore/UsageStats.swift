// Sources/ClaudeBarCore/UsageStats.swift
import Foundation

/// One parsed assistant message containing token usage.
public struct MessageRecord: Sendable {
    public let timestamp: Date
    public let model: String
    public let inputTokens: Int
    public let outputTokens: Int
    public let cacheReadTokens: Int
    public let cacheCreationTokens: Int

    /// All token types summed — matches how Claude tracks rate-limit usage.
    public var totalTokens: Int {
        inputTokens + outputTokens + cacheReadTokens + cacheCreationTokens
    }

    public init(
        timestamp: Date, model: String,
        inputTokens: Int, outputTokens: Int,
        cacheReadTokens: Int, cacheCreationTokens: Int
    ) {
        self.timestamp = timestamp
        self.model = model
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheReadTokens = cacheReadTokens
        self.cacheCreationTokens = cacheCreationTokens
    }
}

/// Aggregated stats for one time window (session or weekly).
public struct WindowStats: Sendable {
    public let tokensUsed: Int
    /// 0–100, capped at 100.
    public let percentage: Double
    /// When this window expires (i.e. the oldest record's timestamp + window duration).
    public let windowEnd: Date

    public init(tokensUsed: Int, percentage: Double, windowEnd: Date) {
        self.tokensUsed = tokensUsed
        self.percentage = percentage
        self.windowEnd = windowEnd
    }
}

/// Fully aggregated snapshot shown in the popover.
public struct UsageStats: Sendable {
    public let session: WindowStats   // last 5 hours
    public let weekly: WindowStats    // last 7 days
    public let monthlyCostUSD: Double // current calendar month
    public let lastUpdated: Date

    public init(
        session: WindowStats, weekly: WindowStats,
        monthlyCostUSD: Double, lastUpdated: Date
    ) {
        self.session = session
        self.weekly = weekly
        self.monthlyCostUSD = monthlyCostUSD
        self.lastUpdated = lastUpdated
    }
}

/// User-configurable ceilings for percentage calculations.
public struct UsageLimits: Sendable {
    public let sessionTokenLimit: Int
    public let weeklyTokenLimit: Int
    /// Calendar weekday for weekly reset: 1=Sun 2=Mon 3=Tue 4=Wed 5=Thu 6=Fri 7=Sat
    public let weeklyResetWeekday: Int
    /// Hour (0-23) at which the weekly window resets
    public let weeklyResetHour: Int

    public static let defaults = UsageLimits(
        sessionTokenLimit:  100_000,   // derived: 26,505 output tokens = 27% on Claude Pro
        weeklyTokenLimit:   1_176_000, // derived: 304,029 output tokens = 26% on Claude Pro
        weeklyResetWeekday: 2,         // Monday
        weeklyResetHour:    11         // 11 AM — typical Claude Pro billing reset
    )

    public init(
        sessionTokenLimit: Int,
        weeklyTokenLimit: Int,
        weeklyResetWeekday: Int = 2,
        weeklyResetHour: Int = 0
    ) {
        self.sessionTokenLimit = sessionTokenLimit
        self.weeklyTokenLimit = weeklyTokenLimit
        self.weeklyResetWeekday = weeklyResetWeekday
        self.weeklyResetHour = weeklyResetHour
    }
}
