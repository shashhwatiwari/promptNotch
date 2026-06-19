import AppKit
import Combine
import SwiftUI

final class OverlayWindowController: NSWindowController, NSWindowDelegate {
    private let model: TeleprompterModel
    private var cancellables = Set<AnyCancellable>()
    private var isPlacingWindow = false

    init(model: TeleprompterModel) {
        self.model = model

        let hostingView = NSHostingView(rootView: PromptOverlayView(model: model))
        hostingView.wantsLayer = true
        hostingView.layer?.masksToBounds = false
        hostingView.translatesAutoresizingMaskIntoConstraints = true
        hostingView.autoresizingMask = [.width, .height]

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: model.promptWidth, height: model.promptHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hostingView
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.minSize = NSSize(width: 120, height: 34)

        super.init(window: panel)
        panel.delegate = self
        bind()
        applyWindowState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func windowDidMove(_ notification: Notification) {
        guard !isPlacingWindow else { return }
        guard let frame = window?.frame else { return }
        model.customOrigin = frame.origin
        if model.position != .custom {
            model.position = .custom
        }
    }

    private func bind() {
        model.$isPromptVisible
            .merge(with: model.$isClickThrough.map { _ in self.model.isPromptVisible }.eraseToAnyPublisher())
            .merge(with: model.$isPromptMinimized.map { _ in self.model.isPromptVisible }.eraseToAnyPublisher())
            .sink { [weak self] _ in self?.applyWindowState() }
            .store(in: &cancellables)

        Publishers.CombineLatest3(model.$promptWidth, model.$promptHeight, model.$position)
            .sink { [weak self] _, _, _ in self?.placeWindow() }
            .store(in: &cancellables)

        model.$mode
            .dropFirst()
            .sink { [weak self] mode in self?.apply(mode: mode) }
            .store(in: &cancellables)
    }

    private func applyWindowState() {
        guard let panel = window as? NSPanel else { return }
        panel.ignoresMouseEvents = model.isClickThrough

        if model.isPromptVisible {
            placeWindow()
            panel.orderFrontRegardless()
        } else {
            panel.orderOut(nil)
        }
    }

    private func apply(mode: PromptMode) {
        switch mode {
        case .minimal:
            model.position = .underCamera
            model.promptWidth = 440
            model.visibleLines = 1
            model.promptHeight = model.calculatedHeight()
            model.opacity = 0.78
        case .standard:
            model.position = .underCamera
            model.promptWidth = 620
            model.visibleLines = 3
            model.promptHeight = model.calculatedHeight()
            model.opacity = 0.84
        case .presenter:
            model.position = .topCenter
            model.promptWidth = 820
            model.visibleLines = 6
            model.promptHeight = model.calculatedHeight()
            model.opacity = 0.9
        }
    }

    private func placeWindow() {
        guard let window else { return }

        var frame = window.frame
        let targetWidth = model.isPromptMinimized ? 184 : model.promptWidth
        let targetHeight = model.isPromptMinimized ? 42 : model.promptHeight + 30
        frame.size = CGSize(width: targetWidth, height: targetHeight)

        if model.position == .custom, let origin = model.customOrigin {
            frame.origin = origin
            setFrame(frame, on: window)
            return
        }

        guard let screen = NSScreen.main else {
            setFrame(frame, on: window)
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

        setFrame(frame, on: window)
    }

    private func setFrame(_ frame: NSRect, on window: NSWindow) {
        isPlacingWindow = true
        window.setFrame(frame, display: true, animate: false)
        DispatchQueue.main.async { [weak self] in
            self?.isPlacingWindow = false
        }
    }
}
