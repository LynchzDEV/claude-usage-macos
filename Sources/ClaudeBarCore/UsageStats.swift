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
    public let sessionOutputTokenLimit: Int
    public let weeklyOutputTokenLimit: Int

    public static let defaults = UsageLimits(
        sessionOutputTokenLimit: 140_000,
        weeklyOutputTokenLimit: 980_000
    )

    public init(sessionOutputTokenLimit: Int, weeklyOutputTokenLimit: Int) {
        self.sessionOutputTokenLimit = sessionOutputTokenLimit
        self.weeklyOutputTokenLimit = weeklyOutputTokenLimit
    }
}
