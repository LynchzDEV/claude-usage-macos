// Sources/ClaudeBar/SettingsView.swift
import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("sessionLimit") private var sessionLimit: Int  = 140_000
    @AppStorage("weeklyLimit")  private var weeklyLimit: Int   = 980_000
    @AppStorage("showCostRow")  private var showCostRow: Bool  = true
    @Binding var showingSettings: Bool

    @State private var launchAtLogin: Bool = {
        SMAppService.mainApp.status == .enabled
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("ClaudeBar Settings")
                    .font(.headline)
                Spacer()
                Button("Done") { showingSettings = false }
                    .keyboardShortcut(.return)
            }
            .padding([.horizontal, .top], 20)
            .padding(.bottom, 12)

            Divider()

            Form {
                Section {
                    Button("Reset to Claude Pro defaults") {
                        sessionLimit = 100_000
                        weeklyLimit  = 1_176_000
                    }
                    .foregroundStyle(.red)
                }

                Section("Rate Limit Ceilings") {
                    LabeledContent("Session (5h) tokens") {
                        TextField("140000", value: $sessionLimit, format: .number)
                            .frame(width: 100)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Weekly tokens") {
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
                                if enabled { try SMAppService.mainApp.register() }
                                else       { try SMAppService.mainApp.unregister() }
                            } catch {}
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
        .frame(width: 320)
        .background(.ultraThinMaterial)
    }
}
