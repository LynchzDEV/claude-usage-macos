import XCTest
@testable import ClaudeBarCore

@MainActor
final class JSONLParserTests: XCTestCase {
    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func test_parse_extractsAssistantMessagesWithUsage() throws {
        let jsonl = """
        {"type":"user","timestamp":"2026-03-30T10:00:00.000Z","message":{"role":"user","content":"hi"}}
        {"type":"assistant","timestamp":"2026-03-30T10:00:01.000Z","message":{"model":"claude-sonnet-4-6","usage":{"input_tokens":10,"output_tokens":50,"cache_read_input_tokens":100,"cache_creation_input_tokens":20}}}
        {"type":"assistant","timestamp":"2026-03-30T10:00:02.000Z","message":{"model":"claude-opus-4-6","usage":{"input_tokens":5,"output_tokens":30,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}
        """
        try writeJSONL(jsonl, named: "session.jsonl")

        let records = try JSONLParser.parse(directory: tempDir)

        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records[0].model, "claude-sonnet-4-6")
        XCTAssertEqual(records[0].outputTokens, 50)
        XCTAssertEqual(records[0].inputTokens, 10)
        XCTAssertEqual(records[0].cacheReadTokens, 100)
        XCTAssertEqual(records[0].cacheCreationTokens, 20)
        XCTAssertEqual(records[1].model, "claude-opus-4-6")
        XCTAssertEqual(records[1].outputTokens, 30)
    }

    func test_parse_skipsAssistantMessagesWithoutUsage() throws {
        let jsonl = """
        {"type":"assistant","timestamp":"2026-03-30T10:00:00.000Z","message":{"model":"claude-sonnet-4-6"}}
        {"type":"assistant","timestamp":"2026-03-30T10:00:01.000Z","message":{"model":"claude-sonnet-4-6","usage":{"input_tokens":5,"output_tokens":10,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}
        """
        try writeJSONL(jsonl, named: "session.jsonl")

        let records = try JSONLParser.parse(directory: tempDir)

        XCTAssertEqual(records.count, 1)
    }

    func test_parse_skipsNonAssistantLines() throws {
        let jsonl = """
        {"type":"user","timestamp":"2026-03-30T10:00:00.000Z","message":{"role":"user","content":"hello"}}
        {"type":"tool_result","timestamp":"2026-03-30T10:00:00.100Z"}
        """
        try writeJSONL(jsonl, named: "session.jsonl")

        let records = try JSONLParser.parse(directory: tempDir)

        XCTAssertEqual(records.count, 0)
    }

    func test_parse_skipsMalformedLines() throws {
        let jsonl = """
        not json at all
        {"type":"assistant","timestamp":"2026-03-30T10:00:01.000Z","message":{"model":"claude-sonnet-4-6","usage":{"input_tokens":1,"output_tokens":2,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}
        """
        try writeJSONL(jsonl, named: "session.jsonl")

        let records = try JSONLParser.parse(directory: tempDir)

        XCTAssertEqual(records.count, 1)
    }

    func test_parse_since_skipsFilesOlderThanCutoff() throws {
        let jsonl = """
        {"type":"assistant","timestamp":"2026-03-30T10:00:00.000Z","message":{"model":"claude-sonnet-4-6","usage":{"input_tokens":1,"output_tokens":2,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}
        """
        let fileURL = try writeJSONL(jsonl, named: "old.jsonl")

        // Back-date the file
        let pastDate = Date().addingTimeInterval(-7200)
        try FileManager.default.setAttributes(
            [.modificationDate: pastDate],
            ofItemAtPath: fileURL.path
        )

        let records = try JSONLParser.parse(directory: tempDir, since: Date().addingTimeInterval(-60))

        XCTAssertEqual(records.count, 0)
    }

    func test_parse_walksSubdirectories() throws {
        let subdir = tempDir.appendingPathComponent("project/session")
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)
        let jsonl = """
        {"type":"assistant","timestamp":"2026-03-30T10:00:00.000Z","message":{"model":"claude-sonnet-4-6","usage":{"input_tokens":1,"output_tokens":5,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}
        """
        let url = subdir.appendingPathComponent("data.jsonl")
        try jsonl.write(to: url, atomically: true, encoding: .utf8)

        let records = try JSONLParser.parse(directory: tempDir)

        XCTAssertEqual(records.count, 1)
    }

    // MARK: - Helpers

    @discardableResult
    func writeJSONL(_ content: String, named name: String) throws -> URL {
        let url = tempDir.appendingPathComponent(name)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
