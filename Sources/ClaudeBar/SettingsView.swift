// Sources/ClaudeBar/SettingsView.swift
import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("sessionLimit") private var sessionLimit: Int = 140_000
    @AppStorage("weeklyLimit")  private var weeklyLimit: Int  = 980_000
    @AppStorage("showCostRow")  private var showCostRow: Bool = true
    @Environment(\.dismiss) private var dismiss

    @State private var launchAtLogin: Bool = {
        SMAppService.mainApp.status == .enabled
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("ClaudeBar Settings")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.return)
            }
            .padding([.horizontal, .top], 20)
            .padding(.bottom, 12)

            Divider()

            Form {
                Section("Rate Limit Ceilings") {
                    LabeledContent("Session (5h) output tokens") {
                        TextField("140000", value: $sessionLimit, format: .number)
                            .frame(width: 100)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Weekly (7d) output tokens") {
                        TextField("980000", value: $weeklyLimit, format: .number)
                            .frame(width: 100)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Display") {
                    Toggle("Show cost estimate row", isOn: $showCostRow)
                }

                Section("System") {
                    Toggle("Launch at login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { _, enabled in
                            do {
                                if enabled {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            } catch {
                                // Launch-at-login requires a signed app bundle;
                                // silently ignore in dev builds
                            }
                        }
                }

                Section("Pricing reference (per 1M tokens)") {
                    LabeledContent("Input",          value: "$3.00")
                    LabeledContent("Output",         value: "$15.00")
                    LabeledContent("Cache read",     value: "$0.30")
                    LabeledContent("Cache creation", value: "$3.75")
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 380, height: 440)
        .background(.ultraThinMaterial)
    }
}
