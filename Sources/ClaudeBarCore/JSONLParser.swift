import Foundation

public struct JSONLParser {

    // MARK: - Decodable helpers (internal to this file)

    private struct RawLine: Decodable {
        let type: String
        let timestamp: String
        let message: RawMessageBody?

        struct RawMessageBody: Decodable {
            let id: String?      // Anthropic API message ID — used for deduplication
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

    private struct ParsedEntry {
        let messageId: String?
        let record: MessageRecord
    }

    // ISO8601DateFormatter is not Sendable, but parse() is called sequentially —
    // nonisolated(unsafe) lets it be used from any concurrency context.
    nonisolated(unsafe) private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    // MARK: - Public API

    /// Parse all `.jsonl` files under `directory` (recursive), globally deduplicated.
    ///
    /// Claude Code emits multiple JSONL records per API response (one per content
    /// block during streaming), all sharing the same `message.id`. Streaming chunks
    /// have low `output_tokens` (1–8); the final record has the true total. The same
    /// final record also appears in both parent session and subagent JSONL files.
    ///
    /// This function deduplicates globally across all files, keeping the record with
    /// the **highest `output_tokens`** per `message.id` — which is always the final,
    /// complete record.
    public static func parse(directory: URL, since: Date? = nil) throws -> [MessageRecord] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var allEntries: [ParsedEntry] = []

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "jsonl" else { continue }

            if let since {
                let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey])
                if let modDate = values?.contentModificationDate, modDate < since {
                    continue
                }
            }

            allEntries += parseEntries(at: fileURL)
        }

        // Global dedup: for each message.id keep the record with highest output_tokens.
        var byMessageId: [String: MessageRecord] = [:]
        var noId: [MessageRecord] = []

        for entry in allEntries {
            guard let mid = entry.messageId else {
                noId.append(entry.record)
                continue
            }
            if let existing = byMessageId[mid] {
                if entry.record.outputTokens > existing.outputTokens {
                    byMessageId[mid] = entry.record
                }
            } else {
                byMessageId[mid] = entry.record
            }
        }

        return Array(byMessageId.values) + noId
    }

    // MARK: - Private

    private static func parseEntries(at url: URL) -> [ParsedEntry] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        var entries: [ParsedEntry] = []

        for line in content.split(separator: "\n", omittingEmptySubsequences: true) {
            guard
                let data = line.data(using: .utf8),
                let raw = try? JSONDecoder().decode(RawLine.self, from: data),
                raw.type == "assistant",
                let usage = raw.message?.usage,
                let model = raw.message?.model,
                let ts = iso8601.date(from: raw.timestamp)
            else { continue }

            entries.append(ParsedEntry(
                messageId: raw.message?.id,
                record: MessageRecord(
                    timestamp: ts,
                    model: model,
                    inputTokens: usage.input_tokens ?? 0,
                    outputTokens: usage.output_tokens ?? 0,
                    cacheReadTokens: usage.cache_read_input_tokens ?? 0,
                    cacheCreationTokens: usage.cache_creation_input_tokens ?? 0
                )
            ))
        }

        return entries
    }

    // Kept for test compatibility.
    static func parseFile(at url: URL) -> [MessageRecord] {
        parseEntries(at: url).map(\.record)
    }
}
