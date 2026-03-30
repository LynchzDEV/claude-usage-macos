import Foundation

public struct PricingTable: Sendable {
    public struct ModelPricing: Sendable {
        public let inputPer1M: Double
        public let outputPer1M: Double
        public let cacheReadPer1M: Double
        public let cacheCreationPer1M: Double
    }

    public var rates: [String: ModelPricing]

    /// Current Anthropic pricing as of 2026-03.
    public static let `default` = PricingTable(rates: [
        "claude-sonnet-4-6": ModelPricing(
            inputPer1M: 3.0, outputPer1M: 15.0,
            cacheReadPer1M: 0.30, cacheCreationPer1M: 3.75
        ),
        "claude-sonnet-4-5-20250929": ModelPricing(
            inputPer1M: 3.0, outputPer1M: 15.0,
            cacheReadPer1M: 0.30, cacheCreationPer1M: 3.75
        ),
        "claude-opus-4-6": ModelPricing(
            inputPer1M: 15.0, outputPer1M: 75.0,
            cacheReadPer1M: 1.50, cacheCreationPer1M: 18.75
        ),
        "claude-opus-4-5-20251101": ModelPricing(
            inputPer1M: 15.0, outputPer1M: 75.0,
            cacheReadPer1M: 1.50, cacheCreationPer1M: 18.75
        ),
        "claude-haiku-4-5-20251001": ModelPricing(
            inputPer1M: 0.80, outputPer1M: 4.0,
            cacheReadPer1M: 0.08, cacheCreationPer1M: 1.00
        ),
    ])

    /// Fallback for models not in the table (uses Sonnet 4 rates).
    static let fallback = ModelPricing(
        inputPer1M: 3.0, outputPer1M: 15.0,
        cacheReadPer1M: 0.30, cacheCreationPer1M: 3.75
    )
}

public struct CostCalculator {
    public static func estimate(
        records: [MessageRecord],
        pricing: PricingTable = .default
    ) -> Double {
        records.reduce(0.0) { total, record in
            let rates = pricing.rates[record.model] ?? PricingTable.fallback
            return total
                + Double(record.inputTokens)         / 1_000_000 * rates.inputPer1M
                + Double(record.outputTokens)        / 1_000_000 * rates.outputPer1M
                + Double(record.cacheReadTokens)     / 1_000_000 * rates.cacheReadPer1M
                + Double(record.cacheCreationTokens) / 1_000_000 * rates.cacheCreationPer1M
        }
    }
}
