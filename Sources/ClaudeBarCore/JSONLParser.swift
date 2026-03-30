import Foundation

public struct JSONLParser {

    // MARK: - Decodable helpers (internal to this file)

    private struct RawLine: Decodable {
        let type: String
        let timestamp: String
        let message: RawMessageBody?

        struct RawMessageBody: Decodable {
            let model: String?
            let usage: RawUsage?
        }

        struct RawUsage: Decodable {
            let input_tokens: Int?
            let output_tokens: Int?
            let cache_read_input_tokens: Int?
            let cache_creation_input_tokens: Int?
        }
    }

    // ISO8601DateFormatter is not Sendable, but parse() is called sequentially —
    // nonisolated(unsafe) lets it be used from any concurrency context.
    nonisolated(unsafe) private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    // MARK: - Public API

    /// Parse all `.jsonl` files under `directory` (recursive).
    ///
    /// - Parameter since: When provided, skips files whose modification date
    ///   is older than this date. Pass `nil` for a full parse.
    public static func parse(directory: URL, since: Date? = nil) throws -> [MessageRecord] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var records: [MessageRecord] = []

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "jsonl" else { continue }

            if let since {
                let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey])
                if let modDate = values?.contentModificationDate, modDate < since {
                    continue
                }
            }

            records += parseFile(at: fileURL)
        }

        return records
    }

    // MARK: - Private

    static func parseFile(at url: URL) -> [MessageRecord] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        var records: [MessageRecord] = []

        for line in content.split(separator: "\n", omittingEmptySubsequences: true) {
            guard
                let data = line.data(using: .utf8),
                let raw = try? JSONDecoder().decode(RawLine.self, from: data),
                raw.type == "assistant",
                let usage = raw.message?.usage,
                let model = raw.message?.model,
                let ts = iso8601.date(from: raw.timestamp)
            else { continue }

            records.append(MessageRecord(
                timestamp: ts,
                model: model,
                inputTokens: usage.input_tokens ?? 0,
                outputTokens: usage.output_tokens ?? 0,
                cacheReadTokens: usage.cache_read_input_tokens ?? 0,
                cacheCreationTokens: usage.cache_creation_input_tokens ?? 0
            ))
        }

        return records
    }
}
