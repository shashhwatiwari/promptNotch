import AppKit
import Combine
import Foundation

enum PromptTheme: String, CaseIterable, Identifiable {
    case dark = "Dark"
    case light = "Light"
    case auto = "Auto"

    var id: String { rawValue }
}

enum PromptPosition: String, CaseIterable, Identifiable {
    case underCamera = "Under Camera"
    case topCenter = "Top Center"
    case leftSide = "Left Side"
    case rightSide = "Right Side"
    case custom = "Custom"

    var id: String { rawValue }
}

enum PromptMode: String, CaseIterable, Identifiable {
    case minimal = "Minimal"
    case standard = "Standard"
    case presenter = "Presenter"

    var id: String { rawValue }
}

protocol PromptReadable: ObservableObject {
    var script: String { get set }
    var wpm: Double { get set }
    var promptWidth: Double { get set }
    var promptHeight: Double { get set }
    var fontSize: Double { get set }
    var lineSpacing: Double { get set }
    var opacity: Double { get set }
    var textWeight: Double { get set }
    var pauseOnHover: Bool { get set }
    var isClickThrough: Bool { get set }
    var showHoverControls: Bool { get set }
    var showProgressBar: Bool { get set }
    var enableTopFade: Bool { get set }
    var enableBottomFade: Bool { get set }
    var topFadeHeight: Double { get set }
    var bottomFadeHeight: Double { get set }
    var theme: PromptTheme { get set }
    var position: PromptPosition { get set }
    var mode: PromptMode { get set }
    var visibleLines: Double { get set }
    var autoSizeEnabled: Bool { get set }
}

extension PromptReadable {
    var wordCount: Int {
        script.split { $0.isWhitespace || $0.isNewline }.count
    }

    var estimatedDuration: TimeInterval {
        guard wpm > 0 else { return 0 }
        return Double(wordCount) / wpm * 60
    }

    var textWeightName: String {
        switch textWeight {
        case ..<0.35: return "Regular"
        case ..<0.7: return "Medium"
        default: return "Bold"
        }
    }

    var nsFontWeight: NSFont.Weight {
        switch textWeight {
        case ..<0.35: return .regular
        case ..<0.7: return .medium
        default: return .bold
        }
    }

    func calculatedHeight() -> Double {
        max(72, (fontSize + lineSpacing) * visibleLines + 42)
    }
}

final class TeleprompterModel: ObservableObject, PromptReadable {
    @Published var script: String = """
    Welcome to Notch Teleprompter.

    Paste, write, or import your script here. Press Start when you are ready, and the prompt will scroll near your camera at the selected pace.
    """

    @Published var isPromptVisible = true
    @Published var isPromptMinimized = false
    @Published var isRunning = false
    @Published var isClickThrough = false
    @Published var wpm: Double = 130
    @Published var promptWidth: Double = 620
    @Published var promptHeight: Double = 150
    @Published var fontSize: Double = 24
    @Published var lineSpacing: Double = 8
    @Published var opacity: Double = 0.84
    @Published var textWeight: Double = 0.45
    @Published var visibleLines: Double = 3
    @Published var autoSizeEnabled = true
    @Published var pauseOnHover = true
    @Published var showHoverControls = true
    @Published var showProgressBar = true
    @Published var enableTopFade = true
    @Published var enableBottomFade = true
    @Published var topFadeHeight: Double = 34
    @Published var bottomFadeHeight: Double = 34
    @Published var theme: PromptTheme = .dark
    @Published var position: PromptPosition = .underCamera
    @Published var mode: PromptMode = .standard
    @Published var customOrigin: CGPoint?
    @Published var contentHeight: Double = 0
    @Published private(set) var scrollOffset: Double = 0
    @Published private(set) var progress: Double = 0

    private var timer: Timer?
    private var lastTick = Date()
    private var cancellables = Set<AnyCancellable>()

    private enum Keys {
        static let script = "DynamicNotch.Script"
        static let wpm = "DynamicNotch.WPM"
        static let promptWidth = "DynamicNotch.PromptWidth"
        static let promptHeight = "DynamicNotch.PromptHeight"
        static let fontSize = "DynamicNotch.FontSize"
        static let lineSpacing = "DynamicNotch.LineSpacing"
        static let opacity = "DynamicNotch.Opacity"
        static let textWeight = "DynamicNotch.TextWeight"
        static let visibleLines = "DynamicNotch.VisibleLines"
        static let autoSizeEnabled = "DynamicNotch.AutoSizeEnabled"
        static let pauseOnHover = "DynamicNotch.PauseOnHover"
        static let showHoverControls = "DynamicNotch.ShowHoverControls"
        static let showProgressBar = "DynamicNotch.ShowProgressBar"
        static let enableTopFade = "DynamicNotch.EnableTopFade"
        static let enableBottomFade = "DynamicNotch.EnableBottomFade"
        static let topFadeHeight = "DynamicNotch.TopFadeHeight"
        static let bottomFadeHeight = "DynamicNotch.BottomFadeHeight"
        static let theme = "DynamicNotch.Theme"
        static let position = "DynamicNotch.Position"
        static let mode = "DynamicNotch.Mode"
        static let isClickThrough = "DynamicNotch.ClickThrough"
        static let isPromptMinimized = "DynamicNotch.PromptMinimized"
    }

    init() {
        loadSettings()
        observeSettingsChanges()
    }

    func start() {
        guard !script.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isRunning = true
        isPromptVisible = true
        isPromptMinimized = false
        lastTick = Date()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.advance()
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
        scrollOffset = 0
        progress = 0
    }

    func scrollBack() {
        scrollOffset = max(0, scrollOffset - max(36, fontSize * 3.2))
        updateProgress()
    }

    func toggleRunning() {
        isRunning ? pause() : start()
    }

    func showPrompt() {
        isPromptVisible = true
        isPromptMinimized = false
    }

    func closePrompt() {
        pause()
        isPromptVisible = false
    }

    func toggleMinimized() {
        isPromptVisible = true
        isPromptMinimized.toggle()
    }

    func importScript(from url: URL) throws {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        script = try String(contentsOf: url, encoding: .utf8)
        reset()
    }

    func apply(from draft: PromptDraft) {
        script = draft.script
        wpm = draft.wpm
        promptWidth = draft.promptWidth
        promptHeight = draft.autoSizeEnabled ? draft.calculatedHeight() : draft.promptHeight
        fontSize = draft.fontSize
        lineSpacing = draft.lineSpacing
        opacity = draft.opacity
        textWeight = draft.textWeight
        visibleLines = draft.visibleLines
        autoSizeEnabled = draft.autoSizeEnabled
        isClickThrough = draft.isClickThrough
        pauseOnHover = draft.pauseOnHover
        showHoverControls = draft.showHoverControls
        showProgressBar = draft.showProgressBar
        enableTopFade = draft.enableTopFade
        enableBottomFade = draft.enableBottomFade
        topFadeHeight = draft.topFadeHeight
        bottomFadeHeight = draft.bottomFadeHeight
        theme = draft.theme
        position = draft.position
        mode = draft.mode
        reset()
    }

    private func advance() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastTick)
        lastTick = now

        let pixelsPerSecond = max(12, wpm * 0.95)
        scrollOffset += pixelsPerSecond * elapsed

        updateProgress()

        if progress >= 1 {
            pause()
        }
    }

    private func updateProgress() {
        let roughTotalPixels = max(promptHeight, contentHeight, Double(wordCount) * fontSize * 0.44)
        progress = min(1, max(0, scrollOffset / roughTotalPixels))
    }

    private func observeSettingsChanges() {
        let publishers: [AnyPublisher<Void, Never>] = [
            $script.map { _ in }.eraseToAnyPublisher(),
            $wpm.map { _ in }.eraseToAnyPublisher(),
            $promptWidth.map { _ in }.eraseToAnyPublisher(),
            $promptHeight.map { _ in }.eraseToAnyPublisher(),
            $fontSize.map { _ in }.eraseToAnyPublisher(),
            $lineSpacing.map { _ in }.eraseToAnyPublisher(),
            $opacity.map { _ in }.eraseToAnyPublisher(),
            $textWeight.map { _ in }.eraseToAnyPublisher(),
            $visibleLines.map { _ in }.eraseToAnyPublisher(),
            $autoSizeEnabled.map { _ in }.eraseToAnyPublisher(),
            $pauseOnHover.map { _ in }.eraseToAnyPublisher(),
            $showHoverControls.map { _ in }.eraseToAnyPublisher(),
            $showProgressBar.map { _ in }.eraseToAnyPublisher(),
            $enableTopFade.map { _ in }.eraseToAnyPublisher(),
            $enableBottomFade.map { _ in }.eraseToAnyPublisher(),
            $topFadeHeight.map { _ in }.eraseToAnyPublisher(),
            $bottomFadeHeight.map { _ in }.eraseToAnyPublisher(),
            $theme.map { _ in }.eraseToAnyPublisher(),
            $position.map { _ in }.eraseToAnyPublisher(),
            $mode.map { _ in }.eraseToAnyPublisher(),
            $isClickThrough.map { _ in }.eraseToAnyPublisher(),
            $isPromptMinimized.map { _ in }.eraseToAnyPublisher()
        ]

        Publishers.MergeMany(publishers)
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] in self?.saveSettings() }
            .store(in: &cancellables)
    }

    private func loadSettings() {
        let defaults = UserDefaults.standard

        script = defaults.string(forKey: Keys.script) ?? script
        wpm = defaults.object(forKey: Keys.wpm) as? Double ?? wpm
        promptWidth = defaults.object(forKey: Keys.promptWidth) as? Double ?? promptWidth
        promptHeight = defaults.object(forKey: Keys.promptHeight) as? Double ?? promptHeight
        fontSize = defaults.object(forKey: Keys.fontSize) as? Double ?? fontSize
        lineSpacing = defaults.object(forKey: Keys.lineSpacing) as? Double ?? lineSpacing
        opacity = defaults.object(forKey: Keys.opacity) as? Double ?? opacity
        textWeight = defaults.object(forKey: Keys.textWeight) as? Double ?? textWeight
        visibleLines = defaults.object(forKey: Keys.visibleLines) as? Double ?? visibleLines
        autoSizeEnabled = defaults.object(forKey: Keys.autoSizeEnabled) as? Bool ?? autoSizeEnabled
        pauseOnHover = defaults.object(forKey: Keys.pauseOnHover) as? Bool ?? pauseOnHover
        showHoverControls = defaults.object(forKey: Keys.showHoverControls) as? Bool ?? showHoverControls
        showProgressBar = defaults.object(forKey: Keys.showProgressBar) as? Bool ?? showProgressBar
        enableTopFade = defaults.object(forKey: Keys.enableTopFade) as? Bool ?? enableTopFade
        enableBottomFade = defaults.object(forKey: Keys.enableBottomFade) as? Bool ?? enableBottomFade
        topFadeHeight = defaults.object(forKey: Keys.topFadeHeight) as? Double ?? topFadeHeight
        bottomFadeHeight = defaults.object(forKey: Keys.bottomFadeHeight) as? Double ?? bottomFadeHeight
        theme = defaults.string(forKey: Keys.theme).flatMap(PromptTheme.init(rawValue:)) ?? theme
        position = defaults.string(forKey: Keys.position).flatMap(PromptPosition.init(rawValue:)) ?? position
        mode = defaults.string(forKey: Keys.mode).flatMap(PromptMode.init(rawValue:)) ?? mode
        isClickThrough = defaults.object(forKey: Keys.isClickThrough) as? Bool ?? isClickThrough
        isPromptMinimized = defaults.object(forKey: Keys.isPromptMinimized) as? Bool ?? isPromptMinimized
    }

    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(script, forKey: Keys.script)
        defaults.set(wpm, forKey: Keys.wpm)
        defaults.set(promptWidth, forKey: Keys.promptWidth)
        defaults.set(promptHeight, forKey: Keys.promptHeight)
        defaults.set(fontSize, forKey: Keys.fontSize)
        defaults.set(lineSpacing, forKey: Keys.lineSpacing)
        defaults.set(opacity, forKey: Keys.opacity)
        defaults.set(textWeight, forKey: Keys.textWeight)
        defaults.set(visibleLines, forKey: Keys.visibleLines)
        defaults.set(autoSizeEnabled, forKey: Keys.autoSizeEnabled)
        defaults.set(pauseOnHover, forKey: Keys.pauseOnHover)
        defaults.set(showHoverControls, forKey: Keys.showHoverControls)
        defaults.set(showProgressBar, forKey: Keys.showProgressBar)
        defaults.set(enableTopFade, forKey: Keys.enableTopFade)
        defaults.set(enableBottomFade, forKey: Keys.enableBottomFade)
        defaults.set(topFadeHeight, forKey: Keys.topFadeHeight)
        defaults.set(bottomFadeHeight, forKey: Keys.bottomFadeHeight)
        defaults.set(theme.rawValue, forKey: Keys.theme)
        defaults.set(position.rawValue, forKey: Keys.position)
        defaults.set(mode.rawValue, forKey: Keys.mode)
        defaults.set(isClickThrough, forKey: Keys.isClickThrough)
        defaults.set(isPromptMinimized, forKey: Keys.isPromptMinimized)
    }
}
