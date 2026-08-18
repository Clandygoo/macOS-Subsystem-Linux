import SwiftUI

@main
struct MSLFileManagerApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .frame(minWidth: 800, minHeight: 500)
                .onAppear {
                    Task {
                        await appState.vmLifecycle.refreshStatus()
                        await appState.diskMonitor.refreshDisks()
                    }
                }
        }
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(after: .pasteboard) {
                ViewModePicker()
            }

            CommandGroup(after: .newItem) {
                Button("New Window") {
                    NSApplication.shared.keyWindow?
                        .contentViewController?
                        .performSegue(
                            withIdentifier: "newWindow",
                            sender: nil
                        )
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView()
                .environment(appState)
        }

        Window("AI Assistant", id: "ai-assistant") {
            AIAssistantPanel()
                .environment(appState)
        }
        .defaultSize(width: 400, height: 600)

        Window("Disk Manager", id: "disk-manager") {
            DiskManagerView()
                .environment(appState)
        }
        .defaultSize(width: 500, height: 400)
    }
}
