// Sources/ClaudeBar/ClaudeBarApp.swift
import SwiftUI

@main
struct ClaudeBarApp: App {
    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .padding(4)
        } label: {
            Image(systemName: "brain")
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)
    }
}
