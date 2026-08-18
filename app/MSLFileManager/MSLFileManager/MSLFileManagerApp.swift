import SwiftUI

@main
struct MSLFileManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 500)
                .onAppear {
                    Task {
                        await appState.vmLifecycle.autoStartIfNeeded()
                        appState.vmStatus = appState.vmLifecycle.status
                        appState.isVMStarting = false
                        await appState.diskMonitor.refreshDisks()
                    }
                }
        }
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    appState.addTab()
                }
                .keyboardShortcut("t", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }

        Window("AI Assistant", id: "ai-assistant") {
            AIAssistantPanel()
                .environmentObject(appState)
        }
        .defaultSize(width: 400, height: 600)

        Window("Disk Manager", id: "disk-manager") {
            DiskManagerView()
                .environmentObject(appState)
        }
        .defaultSize(width: 500, height: 400)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }
}
