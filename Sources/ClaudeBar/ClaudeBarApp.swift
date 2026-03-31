// Sources/ClaudeBar/ClaudeBarApp.swift
import SwiftUI
import AppKit

@main
struct ClaudeBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No windows — menu bar only app
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let viewModel = UsageViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Status bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "brain", accessibilityDescription: "Claude")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // Popover — .transient closes on outside click, stays open for inside clicks
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: PopoverView()
                .environmentObject(viewModel)
        )
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
