import AppKit
import SwiftUI

@main
struct TempoApp: App {
    @NSApplicationDelegateAdaptor(TempoAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Tempo", id: "main") {
            ContentView()
                .preferredColorScheme(nil)
        }
        .defaultSize(width: 1_360, height: 900)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Import Score…") {
                    NotificationCenter.default.post(name: .tempoImportScore, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandMenu("Practice") {
                Button("Play or Pause") {
                    NotificationCenter.default.post(name: .tempoTogglePlayback, object: nil)
                }
                .keyboardShortcut(.space, modifiers: [])

                Divider()

                Button("Toggle Focus Mode") {
                    NotificationCenter.default.post(name: .tempoToggleFocus, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])

                Button("Toggle Feedback") {
                    NotificationCenter.default.post(name: .tempoToggleInspector, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command, .option])

                Button("Collapse or Expand Sidebar") {
                    NotificationCenter.default.post(name: .tempoToggleSidebar, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
            }
        }

        Settings {
            TempoSettingsView()
        }
    }
}

final class TempoAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
