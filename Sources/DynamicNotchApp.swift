import AppKit
import SwiftUI
import UniformTypeIdentifiers

@main
struct DynamicNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = TeleprompterModel()

    var body: some Scene {
        WindowGroup("Notch Teleprompter") {
            ControlView(model: model)
                .frame(minWidth: 860, minHeight: 620)
                .onAppear {
                    appDelegate.configure(with: model)
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayController: OverlayWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func configure(with model: TeleprompterModel) {
        guard overlayController == nil else { return }
        let controller = OverlayWindowController(model: model)
        overlayController = controller
        controller.showWindow(nil)
    }
}

