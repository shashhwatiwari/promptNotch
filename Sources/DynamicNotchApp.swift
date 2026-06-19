import AppKit
import SwiftUI

@main
struct DynamicNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuContent(model: appDelegate.model)
        } label: {
            Image(systemName: "rectangle.topthird.inset.filled")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.menu)
    }
}

struct MenuContent: View {
    @ObservedObject var model: TeleprompterModel

    var body: some View {
        Button {
            if model.isPromptVisible {
                model.closePrompt()
            } else {
                model.showPrompt()
            }
        } label: {
            Label(model.isPromptVisible ? "Hide Prompter" : "Show Prompter",
                  systemImage: model.isPromptVisible ? "eye.slash" : "eye")
        }
        .keyboardShortcut("h", modifiers: [.command, .option])

        Divider()

        Button {
            model.toggleRunning()
        } label: {
            Label(model.isRunning ? "Pause" : "Play",
                  systemImage: model.isRunning ? "pause.fill" : "play.fill")
        }
        .keyboardShortcut("p", modifiers: [.command, .option])

        Button {
            model.scrollBack()
        } label: {
            Label("Scroll Back", systemImage: "backward.fill")
        }

        Button {
            model.reset()
        } label: {
            Label("Reset", systemImage: "arrow.counterclockwise")
        }

        Button {
            model.toggleMinimized()
        } label: {
            Label(model.isPromptMinimized ? "Expand Teleprompter" : "Minimize Teleprompter",
                  systemImage: model.isPromptMinimized ? "arrow.down.right.and.arrow.up.left" : "minus")
        }

        Divider()

        Button {
            AppDelegate.shared?.showSettingsWindow(nil)
        } label: {
            Label("Settings", systemImage: "gearshape")
        }
        .keyboardShortcut(",", modifiers: [.command])

        Divider()

        Button(role: .destructive) {
            NSApp.terminate(nil)
        } label: {
            Label("Exit", systemImage: "xmark.circle")
        }
        .keyboardShortcut("q", modifiers: [.command])
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?

    let model = TeleprompterModel()
    private var overlayController: OverlayWindowController?
    private var settingsController: SettingsWindowController?

    override init() {
        super.init()
        Self.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        overlayController = OverlayWindowController(model: model)
        overlayController?.showWindow(nil)
        NSApp.setActivationPolicy(.accessory)
    }

    @objc func showSettingsWindow(_ sender: Any?) {
        if settingsController == nil {
            settingsController = SettingsWindowController(model: model)
        }
        settingsController?.show()
    }
}
