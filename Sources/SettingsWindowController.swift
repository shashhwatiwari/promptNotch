import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private let model: TeleprompterModel
    private let draft: PromptDraft

    init(model: TeleprompterModel) {
        self.model = model
        self.draft = PromptDraft(model: model)

        let contentView = ControlView(model: model, draft: draft)
        let hostingController = NSHostingController(rootView: contentView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 980, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "DynamicNotch Settings"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        draft.reload(from: model)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        model.apply(from: draft)
        sender.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
        return false
    }
}
