import AppKit
import Combine
import SwiftUI

final class OverlayWindowController: NSWindowController, NSWindowDelegate {
    private let model: TeleprompterModel
    private var cancellables = Set<AnyCancellable>()

    init(model: TeleprompterModel) {
        self.model = model

        let hostingController = NSHostingController(rootView: PromptOverlayView(model: model))
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: model.promptWidth, height: model.promptHeight),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )

        panel.contentViewController = hostingController
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true

        super.init(window: panel)
        panel.delegate = self
        bind()
        applyWindowState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func windowDidMove(_ notification: Notification) {
        guard let frame = window?.frame else { return }
        model.customOrigin = frame.origin
        if model.position != .custom {
            model.position = .custom
        }
    }

    func windowDidResize(_ notification: Notification) {
        guard let frame = window?.frame else { return }
        model.promptWidth = frame.width
        model.promptHeight = frame.height
    }

    private func bind() {
        model.$isPromptVisible
            .merge(with: model.$isClickThrough.map { _ in self.model.isPromptVisible }.eraseToAnyPublisher())
            .sink { [weak self] _ in self?.applyWindowState() }
            .store(in: &cancellables)

        Publishers.CombineLatest3(model.$promptWidth, model.$promptHeight, model.$position)
            .sink { [weak self] _, _, _ in self?.placeWindow() }
            .store(in: &cancellables)

        model.$mode
            .sink { [weak self] mode in self?.apply(mode: mode) }
            .store(in: &cancellables)
    }

    private func applyWindowState() {
        guard let panel = window as? NSPanel else { return }
        panel.ignoresMouseEvents = model.isClickThrough

        if model.isPromptVisible {
            panel.orderFrontRegardless()
            placeWindow()
        } else {
            panel.orderOut(nil)
        }
    }

    private func apply(mode: PromptMode) {
        switch mode {
        case .meeting:
            model.position = .underCamera
            model.promptWidth = 560
            model.promptHeight = 128
            model.opacity = 0.78
        case .presentation:
            model.position = .topCenter
            model.promptWidth = 820
            model.promptHeight = 260
            model.opacity = 0.9
        case .recording:
            model.position = .underCamera
            model.promptWidth = 700
            model.promptHeight = 190
            model.opacity = 0.88
        }
    }

    private func placeWindow() {
        guard let window else { return }

        var frame = window.frame
        frame.size = CGSize(width: model.promptWidth, height: model.promptHeight)

        if model.position == .custom, let origin = model.customOrigin {
            frame.origin = origin
            window.setFrame(frame, display: true)
            return
        }

        guard let screen = NSScreen.main else {
            window.setFrame(frame, display: true)
            return
        }

        let visible = screen.visibleFrame
        let centerX = visible.midX - frame.width / 2

        switch model.position {
        case .underCamera:
            frame.origin = CGPoint(x: centerX, y: visible.maxY - frame.height - 72)
        case .topCenter:
            frame.origin = CGPoint(x: centerX, y: visible.maxY - frame.height - 28)
        case .leftSide:
            frame.origin = CGPoint(x: visible.minX + 24, y: visible.midY - frame.height / 2)
        case .rightSide:
            frame.origin = CGPoint(x: visible.maxX - frame.width - 24, y: visible.midY - frame.height / 2)
        case .custom:
            break
        }

        window.setFrame(frame, display: true, animate: false)
    }
}

