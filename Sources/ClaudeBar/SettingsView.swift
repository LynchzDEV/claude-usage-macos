// Sources/ClaudeBar/SettingsView.swift
import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("sessionLimit")        private var sessionLimit: Int  = 140_000
    @AppStorage("weeklyLimit")         private var weeklyLimit: Int   = 980_000
    @AppStorage("weeklyResetWeekday")  private var weeklyResetWeekday: Int = 2   // Monday
    @AppStorage("weeklyResetHour")     private var weeklyResetHour: Int    = 11
    @AppStorage("showCostRow")         private var showCostRow: Bool  = true
    @Environment(\.dismiss) private var dismiss

    @State private var launchAtLogin: Bool = {
        SMAppService.mainApp.status == .enabled
    }()

    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                Section {
                    Button("Reset to Claude Pro defaults") {
                        sessionLimit       = 100_000
                        weeklyLimit        = 1_176_000
                        weeklyResetWeekday = 2
                        weeklyResetHour    = 11
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

                Section("Weekly Reset Schedule") {
                    LabeledContent("Reset day") {
                        Picker("", selection: $weeklyResetWeekday) {
                            ForEach(1...7, id: \.self) { day in
                                Text(weekdays[day - 1]).tag(day)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 80)
                    }
                    LabeledContent("Reset hour (0–23)") {
                        TextField("0", value: $weeklyResetHour, format: .number)
                            .frame(width: 50)
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
        .frame(width: 380, height: 480)
        .background(.ultraThinMaterial)
    }
}
