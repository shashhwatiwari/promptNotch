import AppKit
import Foundation

final class PromptDraft: ObservableObject, PromptReadable {
    @Published var script: String
    @Published var wpm: Double
    @Published var promptWidth: Double
    @Published var promptHeight: Double
    @Published var fontSize: Double
    @Published var lineSpacing: Double
    @Published var opacity: Double
    @Published var textWeight: Double
    @Published var visibleLines: Double
    @Published var autoSizeEnabled: Bool
    @Published var isClickThrough: Bool
    @Published var pauseOnHover: Bool
    @Published var showHoverControls: Bool
    @Published var showProgressBar: Bool
    @Published var enableTopFade: Bool
    @Published var enableBottomFade: Bool
    @Published var topFadeHeight: Double
    @Published var bottomFadeHeight: Double
    @Published var theme: PromptTheme
    @Published var position: PromptPosition
    @Published var mode: PromptMode

    init(model: TeleprompterModel) {
        script = model.script
        wpm = model.wpm
        promptWidth = model.promptWidth
        promptHeight = model.promptHeight
        fontSize = model.fontSize
        lineSpacing = model.lineSpacing
        opacity = model.opacity
        textWeight = model.textWeight
        visibleLines = model.visibleLines
        autoSizeEnabled = model.autoSizeEnabled
        isClickThrough = model.isClickThrough
        pauseOnHover = model.pauseOnHover
        showHoverControls = model.showHoverControls
        showProgressBar = model.showProgressBar
        enableTopFade = model.enableTopFade
        enableBottomFade = model.enableBottomFade
        topFadeHeight = model.topFadeHeight
        bottomFadeHeight = model.bottomFadeHeight
        theme = model.theme
        position = model.position
        mode = model.mode
    }

    func reload(from model: TeleprompterModel) {
        script = model.script
        wpm = model.wpm
        promptWidth = model.promptWidth
        promptHeight = model.promptHeight
        fontSize = model.fontSize
        lineSpacing = model.lineSpacing
        opacity = model.opacity
        textWeight = model.textWeight
        visibleLines = model.visibleLines
        autoSizeEnabled = model.autoSizeEnabled
        isClickThrough = model.isClickThrough
        pauseOnHover = model.pauseOnHover
        showHoverControls = model.showHoverControls
        showProgressBar = model.showProgressBar
        enableTopFade = model.enableTopFade
        enableBottomFade = model.enableBottomFade
        topFadeHeight = model.topFadeHeight
        bottomFadeHeight = model.bottomFadeHeight
        theme = model.theme
        position = model.position
        mode = model.mode
    }

    func applyModePreset() {
        switch mode {
        case .minimal:
            visibleLines = 1
            promptWidth = 440
            opacity = 0.78
        case .standard:
            visibleLines = 3
            promptWidth = 620
            opacity = 0.84
        case .presenter:
            visibleLines = 6
            promptWidth = 820
            opacity = 0.9
        }

        if autoSizeEnabled {
            promptHeight = calculatedHeight()
        }
    }

    func importScript(from url: URL) throws {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        script = try String(contentsOf: url, encoding: .utf8)
    }
}
