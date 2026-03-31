// Sources/ClaudeBar/PopoverView.swift
import SwiftUI
import ClaudeBarCore


struct PopoverView: View {
    @EnvironmentObject private var viewModel: UsageViewModel
    @AppStorage("showCostRow") private var showCostRow: Bool = true
    @State private var showingSettings = false

    var body: some View {
        contentStack
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
    }

    private var contentStack: some View {
        VStack(spacing: 0) {
            headerRow

            Divider().opacity(0.2)

            usageSection

            if showCostRow {
                Divider().opacity(0.2)
                costRow
            }

            Divider().opacity(0.2)

            footerRow
        }
        .frame(width: 320)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "brain")
                .font(.body)
            Text("Claude")
                .font(.headline)
            Spacer()
            if let cost = viewModel.stats?.monthlyCostUSD, showCostRow {
                Text("$\(cost, format: .number.precision(.fractionLength(2)))")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Usage bars

    private var usageSection: some View {
        VStack(spacing: 12) {
            if viewModel.isLoading {
                ProgressView()
                    .padding(.vertical, 20)
            } else if let stats = viewModel.stats {
                usageRow(
                    label: "Session",
                    stats: stats.session,
                    isActive: viewModel.hasActiveSession
                )
                usageRow(
                    label: "Weekly",
                    stats: stats.weekly,
                    isActive: false
                )
            } else {
                Text("No sessions yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 20)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func usageRow(label: String, stats: WindowStats, isActive: Bool) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(isActive ? Color.green : Color.clear)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle().strokeBorder(
                        isActive ? Color.green : Color.secondary.opacity(0.4),
                        lineWidth: 1
                    )
                )

            Text(label)
                .font(.subheadline)
                .frame(width: 56, alignment: .leading)

            GlassProgressBar(value: stats.percentage / 100)

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(Int(stats.percentage))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.primary)
                Text(tokenString(stats.tokensUsed))
                    .font(.system(size: 9).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44, alignment: .trailing)

            Text(timeRemaining(until: stats.windowEnd))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)
        }
    }

    // MARK: - Cost row

    private var costRow: some View {
        HStack {
            Text("Code API cost est.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if let cost = viewModel.stats?.monthlyCostUSD {
                Text("$\(cost, format: .number.precision(.fractionLength(2)))")
                    .font(.subheadline.monospacedDigit())
                Text("this month")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("\u{2014}").foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack {
            Button {
                Task { await viewModel.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.callout)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(viewModel.lastUpdatedString)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button { showingSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.callout)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Helpers

    private func tokenString(_ n: Int) -> String {
        n >= 1_000 ? "\(n / 1_000).\((n % 1_000) / 100)k" : "\(n)"
    }

    private func timeRemaining(until date: Date) -> String {
        let secs = date.timeIntervalSinceNow
        guard secs > 0 else { return "now" }
        let hrs  = Int(secs) / 3600
        let mins = (Int(secs) % 3600) / 60
        if hrs >= 24 {
            // Show "Mon 11 AM" style for distant resets
            let fmt = DateFormatter()
            fmt.dateFormat = "EEE h a"
            return fmt.string(from: date)
        }
        if hrs > 0 { return "\(hrs)h \(mins)m" }
        return "\(mins)m"
    }
}
