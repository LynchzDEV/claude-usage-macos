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
    private var cachedRecords: [MessageRecord] = []
    private var isStarted = false

    init() {
        Self.migrateDefaultsIfNeeded()
        Task { await start() }
    }

    /// One-time migration: replaces old default values that may be stored in UserDefaults
    /// from a previous launch before the correct limits were determined.
    private static func migrateDefaultsIfNeeded() {
        let d = UserDefaults.standard
        if d.integer(forKey: "sessionLimit") == 140_000 { d.set(100_000,   forKey: "sessionLimit") }
        if d.integer(forKey: "weeklyLimit")  == 980_000 { d.set(1_176_000, forKey: "weeklyLimit") }
        if d.integer(forKey: "weeklyResetHour") == 0    { d.set(11,        forKey: "weeklyResetHour") }
    }

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
        guard !isStarted else { return }
        isStarted = true
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
        await loadAndAggregate()
    }

    private func loadAndAggregate() async {
        let dir = claudeProjectsDir
        let now = Date()

        let records = await Task.detached(priority: .background) {
            (try? JSONLParser.parse(directory: dir)) ?? []
        }.value

        cachedRecords = records

        let sessionLimit      = UserDefaults.standard.integer(forKey: "sessionLimit")
        let weeklyLimit       = UserDefaults.standard.integer(forKey: "weeklyLimit")
        let weeklyResetDay    = UserDefaults.standard.integer(forKey: "weeklyResetWeekday")
        let weeklyResetHour   = UserDefaults.standard.integer(forKey: "weeklyResetHour")
        let limits = UsageLimits(
            sessionTokenLimit:    sessionLimit   > 0 ? sessionLimit   : 140_000,
            weeklyTokenLimit:     weeklyLimit    > 0 ? weeklyLimit    : 980_000,
            weeklyResetWeekday:   weeklyResetDay > 0 ? weeklyResetDay : 2,  // Monday
            weeklyResetHour:      weeklyResetHour                           // 0 if not set
        )

        stats = UsageAggregator.aggregate(records: cachedRecords, now: now, limits: limits)
        hasActiveSession = cachedRecords.contains { $0.timestamp > now.addingTimeInterval(-300) }
    }

    // MARK: - Timer + watcher setup

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.fullRefresh() }
        }
    }

    private func startWatcher() {
        fileWatcher = FileWatcher(path: claudeProjectsDir.path) { [weak self] in
            Task { @MainActor [weak self] in await self?.fullRefresh() }
        }
        fileWatcher?.start()
    }

    deinit {
        MainActor.assumeIsolated {
            timer?.invalidate()
            fileWatcher?.stop()
        }
    }
}
