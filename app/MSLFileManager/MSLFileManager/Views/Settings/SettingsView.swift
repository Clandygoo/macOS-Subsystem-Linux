import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            VMSettingsView()
                .tabItem {
                    Label("Virtual Machine", systemImage: "desktopcomputer")
                }

            AISettingsView()
                .tabItem {
                    Label("AI Assistant", systemImage: "brain.head.profile")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("showHiddenFiles") private var showHiddenFiles = false
    @AppStorage("defaultViewMode") private var defaultViewMode = "list"
    @AppStorage("language") private var language = "en"

    var body: some View {
        Form {
            Toggle("Show hidden files by default", isOn: $showHiddenFiles)

            Picker("Default view mode", selection: $defaultViewMode) {
                Text("List").tag("list")
                Text("Icons").tag("icon")
                Text("Columns").tag("column")
            }

            Picker("Language", selection: $language) {
                Text("English").tag("en")
                Text("简体中文").tag("zh")
            }
        }
        .padding()
    }
}

struct VMSettingsView: View {
    @EnvironmentObject private var state: AppState
    @AppStorage("vmCPUs") private var vmCPUs = 4
    @AppStorage("vmMemory") private var vmMemory = "1GiB"
    @AppStorage("vmDisk") private var vmDisk = "20GiB"

    var body: some View {
        Form {
            Section("VM Status") {
                HStack {
                    Text("Status:")
                    Text(state.vmStatus.displayName)
                        .foregroundStyle(state.vmStatus.isRunning ? .green : .red)
                }

                HStack {
                    Button("Start VM") {
                        Task { await state.vmLifecycle.start() }
                    }
                    .disabled(state.vmStatus.isRunning)

                    Button("Stop VM") {
                        Task { await state.vmLifecycle.stop() }
                    }
                    .disabled(!state.vmStatus.isRunning)

                    Button("Restart VM") {
                        Task { await state.vmLifecycle.restart() }
                    }
                }
            }

            Section("Resources") {
                Stepper("CPUs: \(vmCPUs)", value: $vmCPUs, in: 1...8)
                TextField("Memory:", text: $vmMemory)
                TextField("Disk:", text: $vmDisk)
            }
        }
        .padding()
    }
}

struct AISettingsView: View {
    @AppStorage("aiEnabled") private var aiEnabled = false
    @AppStorage("aiProvider") private var aiProvider = "openai"
    @AppStorage("aiAPIKey") private var aiAPIKey = ""

    var body: some View {
        Form {
            Section("AI Integration") {
                Toggle("Enable AI Assistant", isOn: $aiEnabled)

                Picker("Provider", selection: $aiProvider) {
                    Text("OpenAI").tag("openai")
                    Text("Anthropic").tag("anthropic")
                    Text("Local Model").tag("local")
                }
                .disabled(!aiEnabled)

                SecureField("API Key:", text: $aiAPIKey)
                    .disabled(!aiEnabled)
            }
        }
        .padding()
    }
}
