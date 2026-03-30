// Sources/ClaudeBar/UsageViewModel.swift
import Foundation
import SwiftUI
import ClaudeBarCore

@MainActor
final class UsageViewModel: ObservableObject {
    @Published var stats: UsageStats?
    @Published var isLoading: Bool = false
    @Published var hasActiveSession: Bool = false

    private let claudeProjectsDir: URL = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/projects")

    private var fileWatcher: FileWatcher?
    private var timer: Timer?
    // Full record cache — rebuilt on full refresh, appended on incremental
    private var cachedRecords: [MessageRecord] = []
    private var lastParsedAt: Date?

    // MARK: - Public

    var lastUpdatedString: String {
        guard let date = stats?.lastUpdated else { return "Never updated" }
        let elapsed = Int(-date.timeIntervalSinceNow)
        switch elapsed {
        case ..<5:  return "Updated just now"
        case ..<60: return "Updated \(elapsed)s ago"
        default:    return "Updated \(elapsed / 60)m ago"
        }
    }

    func start() async {
        isLoading = true
        await fullRefresh()
        isLoading = false
        startTimer()
        startWatcher()
    }

    func refresh() async {
        await fullRefresh()
    }

    // MARK: - Private refresh

    private func fullRefresh() async {
        lastParsedAt = nil
        cachedRecords = []
        await loadAndAggregate(incremental: false)
    }

    private func incrementalRefresh() async {
        await loadAndAggregate(incremental: true)
    }

    private func loadAndAggregate(incremental: Bool) async {
        let dir = claudeProjectsDir
        let since: Date? = incremental ? lastParsedAt : nil
        let now = Date()

        // JSONLParser.parse is @MainActor-isolated, so it must run on the main actor.
        let newRecords = (try? JSONLParser.parse(directory: dir, since: since)) ?? []

        if incremental {
            cachedRecords.append(contentsOf: newRecords)
        } else {
            cachedRecords = newRecords
        }

        lastParsedAt = now

        let limits = UsageLimits(
            sessionOutputTokenLimit: UserDefaults.standard.object(forKey: "sessionLimit") as? Int ?? 140_000,
            weeklyOutputTokenLimit: UserDefaults.standard.object(forKey: "weeklyLimit") as? Int ?? 980_000
        )

        stats = UsageAggregator.aggregate(records: cachedRecords, now: now, limits: limits)
        hasActiveSession = cachedRecords.contains { $0.timestamp > now.addingTimeInterval(-300) }
    }

    // MARK: - Timer + watcher setup

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.incrementalRefresh() }
        }
    }

    private func startWatcher() {
        fileWatcher = FileWatcher(path: claudeProjectsDir.path) { [weak self] in
            Task { @MainActor [weak self] in await self?.incrementalRefresh() }
        }
        fileWatcher?.start()
    }
}
