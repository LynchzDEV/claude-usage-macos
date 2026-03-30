import XCTest
@testable import ClaudeBarCore

final class CostCalculatorTests: XCTestCase {

    func test_estimate_outputTokensCost() {
        let records = [record(model: "claude-sonnet-4-6", outputTokens: 1_000_000)]

        let cost = CostCalculator.estimate(records: records)

        XCTAssertEqual(cost, 15.0, accuracy: 0.0001)
    }

    func test_estimate_inputTokensCost() {
        let records = [record(model: "claude-sonnet-4-6", inputTokens: 1_000_000)]

        let cost = CostCalculator.estimate(records: records)

        XCTAssertEqual(cost, 3.0, accuracy: 0.0001)
    }

    func test_estimate_allFourTokenTypes() {
        // 3.00 + 15.00 + 0.30 + 3.75 = 22.05
        let records = [record(
            model: "claude-sonnet-4-6",
            inputTokens: 1_000_000,
            outputTokens: 1_000_000,
            cacheReadTokens: 1_000_000,
            cacheCreationTokens: 1_000_000
        )]

        let cost = CostCalculator.estimate(records: records)

        XCTAssertEqual(cost, 22.05, accuracy: 0.0001)
    }

    func test_estimate_unknownModelFallsBackToSonnetPricing() {
        let records = [record(model: "claude-future-model", outputTokens: 1_000_000)]

        let cost = CostCalculator.estimate(records: records)

        XCTAssertEqual(cost, 15.0, accuracy: 0.0001)
    }

    func test_estimate_emptyRecordsReturnsZero() {
        let cost = CostCalculator.estimate(records: [])
        XCTAssertEqual(cost, 0.0)
    }

    func test_estimate_multipleRecordsSumsCorrectly() {
        let records = [
            record(model: "claude-sonnet-4-6", outputTokens: 500_000),
            record(model: "claude-sonnet-4-6", outputTokens: 500_000),
        ]

        let cost = CostCalculator.estimate(records: records)

        XCTAssertEqual(cost, 15.0, accuracy: 0.0001)
    }

    // MARK: - Helper

    func record(
        model: String = "claude-sonnet-4-6",
        inputTokens: Int = 0,
        outputTokens: Int = 0,
        cacheReadTokens: Int = 0,
        cacheCreationTokens: Int = 0
    ) -> MessageRecord {
        MessageRecord(
            timestamp: Date(),
            model: model,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            cacheReadTokens: cacheReadTokens,
            cacheCreationTokens: cacheCreationTokens
        )
    }
}
