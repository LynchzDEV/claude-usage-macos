# Claude Usage — macOS Menu Bar App

A native macOS menu bar app that tracks your [Claude Code](https://claude.ai/code) token usage in real time by reading the local JSONL logs written by the CLI.

![macOS 26](https://img.shields.io/badge/macOS-26%2B-black) ![Swift](https://img.shields.io/badge/Swift-6.0-orange) ![License](https://img.shields.io/badge/license-MIT-blue)

---

## Features

- **Session bar** — rolling 5-hour output-token window with time-to-reset
- **Weekly bar** — fixed weekly window anchored to your billing-cycle reset day/time
- **Token count** — raw token count shown under each percentage for self-calibration
- **Cost estimate** — monthly API cost estimate from your actual usage
- **Auto-refresh** — updates every 60 seconds + instant refresh via FSEvents on file change
- **Native popover** — uses `NSPopover` for reliable click handling on macOS 26 Tahoe
- **Settings** — configurable token limits, weekly reset schedule, launch at login

---

## Requirements

- macOS 26 (Tahoe) or later
- [Claude Code CLI](https://claude.ai/code) installed and used at least once
- Swift 6.0 / Xcode 16+

---

## Installation

```bash
git clone https://github.com/LynchzDEV/claude-usage-macos.git
cd claude-usage-macos
bash run.sh
```

`run.sh` builds the Swift package, wraps the binary in a minimal `.app` bundle, and launches it. The brain icon (𝌭) appears in your menu bar.

---

## How It Works

Claude Code writes one JSONL record per API response to `~/.claude/projects/**/*.jsonl`. Each streaming chunk shares the same `message.id` with low `output_tokens` (1–8); the final chunk has the true count. This app:

1. Reads all JSONL files across every project directory
2. Deduplicates by `message.id`, keeping the record with the **highest `output_tokens`** (the final streaming record)
3. Filters records into a **5-hour rolling session window** and a **fixed weekly window**
4. Calculates percentage against configurable token limits

### Default Limits (Claude Pro / $20 plan)

| Window | Default limit | Basis |
|--------|--------------|-------|
| Session (5h) | 100,000 output tokens | Derived from observed usage data |
| Weekly | 1,176,000 output tokens | Derived from observed usage data |

These are calibrated for **Claude Pro ($20/month)**. If your percentages don't match [claude.ai/settings/usage](https://claude.ai/settings/usage), open **Settings → Reset to Claude Pro defaults** or tune the limits manually.

---

## Settings

Open the popover → gear icon → Settings:

| Setting | Default | Description |
|---------|---------|-------------|
| Session tokens | 100,000 | Output-token ceiling per 5h window |
| Weekly tokens | 1,176,000 | Output-token ceiling per weekly window |
| Weekly reset day | Monday | Day your billing cycle resets |
| Weekly reset hour | 11 | Hour (0–23) your billing cycle resets |
| Show cost row | On | Monthly API cost estimate |
| Launch at login | Off | Start automatically on login |

Use **Reset to Claude Pro defaults** to restore calibrated values at any time.

---

## Project Structure

```
Sources/
  ClaudeBarCore/        # Pure Swift library (no AppKit/SwiftUI)
    JSONLParser.swift   # JSONL reading + deduplication
    UsageAggregator.swift
    UsageStats.swift
    CostCalculator.swift
  ClaudeBar/            # macOS app
    ClaudeBarApp.swift  # NSStatusItem + NSPopover entry point
    UsageViewModel.swift
    PopoverView.swift
    SettingsView.swift
    GlassProgressBar.swift
    FileWatcher.swift   # FSEvents wrapper
Tests/
  ClaudeBarCoreTests/
```

---

## License

MIT
