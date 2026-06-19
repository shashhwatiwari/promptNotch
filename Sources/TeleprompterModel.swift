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
    case meeting = "Meeting"
    case presentation = "Presentation"
    case recording = "Recording"

    var id: String { rawValue }
}

final class TeleprompterModel: ObservableObject {
    @Published var script: String = """
    Welcome to Notch Teleprompter.

    Paste, write, or import your script here. Press Start when you are ready, and the prompt will scroll near your camera at the selected pace.
    """

    @Published var isPromptVisible = true
    @Published var isRunning = false
    @Published var isClickThrough = false
    @Published var wpm: Double = 130
    @Published var promptWidth: Double = 620
    @Published var promptHeight: Double = 150
    @Published var fontSize: Double = 24
    @Published var lineSpacing: Double = 8
    @Published var opacity: Double = 0.84
    @Published var textWeight: Double = 0.45
    @Published var theme: PromptTheme = .dark
    @Published var position: PromptPosition = .underCamera
    @Published var mode: PromptMode = .meeting
    @Published var customOrigin: CGPoint?
    @Published private(set) var scrollOffset: Double = 0
    @Published private(set) var progress: Double = 0

    private var timer: Timer?
    private var lastTick = Date()

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

    func start() {
        guard !script.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isRunning = true
        isPromptVisible = true
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

    func toggleRunning() {
        isRunning ? pause() : start()
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

    private func advance() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastTick)
        lastTick = now

        let pixelsPerSecond = max(12, wpm * 0.95)
        scrollOffset += pixelsPerSecond * elapsed

        let roughTotalPixels = max(promptHeight, Double(wordCount) * fontSize * 0.44)
        progress = min(1, scrollOffset / roughTotalPixels)

        if progress >= 1 {
            pause()
        }
    }
}

