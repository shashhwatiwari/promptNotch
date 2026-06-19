import SwiftUI

struct PromptOverlayView: View {
    @ObservedObject var model: TeleprompterModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showControls = false
    @State private var wasRunningBeforeHover = false

    var body: some View {
        Group {
            if model.isPromptMinimized {
                minimizedIsland
            } else {
                expandedIsland
            }
        }
        .frame(
            width: model.isPromptMinimized ? 184 : model.promptWidth,
            height: model.isPromptMinimized ? 42 : model.promptHeight + 30
        )
        .opacity(focusOpacity)
        .animation(.spring(response: 0.26, dampingFraction: 0.86), value: model.isPromptMinimized)
        .animation(.easeInOut(duration: 0.18), value: showControls)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.16)) {
                showControls = hovering
            }
            handleHover(hovering)
        }
    }

    private var expandedIsland: some View {
        VStack(spacing: 0) {
            notchCap

            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(backgroundColor.opacity(model.opacity))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(borderColor.opacity(usesDarkTheme ? 0.20 : 0.12), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.28), radius: 22, y: 12)

                promptContent
                fadeOverlays

                if model.showProgressBar {
                    progressRail
                }

                if model.showHoverControls && showControls {
                    topCornerControls
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }

                if model.showHoverControls && showControls {
                    hoverControls
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .frame(height: model.promptHeight)
        }
        .padding(.horizontal, 1)
        .padding(.bottom, 2)
    }

    private var minimizedIsland: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(model.isRunning ? Color.green : textColor.opacity(0.42))
                .frame(width: 7, height: 7)

            Text(model.isRunning ? "Prompting" : "Prompt")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))

            if showControls {
                Button {
                    model.toggleMinimized()
                } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                }
                .help("Expand")

                Button {
                    model.closePrompt()
                } label: {
                    Image(systemName: "xmark")
                }
                .help("Close")
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .frame(height: 34)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.92))
                .shadow(color: .black.opacity(0.28), radius: 14, y: 8)
        )
    }

    private var notchCap: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.black)
                .frame(width: 156, height: 30)
                .shadow(color: .black.opacity(0.22), radius: 10, y: 5)

            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(backgroundColor.opacity(model.opacity))
                .frame(width: 54, height: 12)
                .offset(y: 8)
        }
        .zIndex(2)
    }

    private var promptContent: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                movingText
                    .frame(width: max(0, geometry.size.width - 32), alignment: .center)
                    .offset(y: -model.scrollOffset)
                    .animation(.linear(duration: 0.08), value: model.scrollOffset)
                    .background(HeightReader { height in
                        model.contentHeight = height
                    })
                Spacer(minLength: 0)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            .clipped()
        }
        .padding(.vertical, 8)
    }

    private var movingText: some View {
        Text(attributedScript)
            .multilineTextAlignment(.center)
            .lineSpacing(model.lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 16)
            .padding(.top, 26)
            .padding(.bottom, model.promptHeight)
    }

    private var attributedScript: AttributedString {
        let base = model.script.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Paste or import a script in Settings..."
            : model.script
        let text = "\n\(base)\n\n[the end]"
        var attributed = AttributedString(text)
        attributed.font = .system(size: model.fontSize, weight: Font.Weight(model.nsFontWeight), design: .default)
        attributed.foregroundColor = textColor

        let pattern = "\\[[^\\]]+\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return attributed
        }

        let nsText = text as NSString
        for match in regex.matches(in: text, range: NSRange(location: 0, length: nsText.length)) {
            guard
                let stringRange = Range(match.range, in: text),
                let attributedRange = Range(stringRange, in: attributed)
            else { continue }

            attributed[attributedRange].font = .system(size: model.fontSize, weight: Font.Weight(model.nsFontWeight), design: .default).italic()
            attributed[attributedRange].foregroundColor = textColor.opacity(0.42)
        }

        return attributed
    }

    private var fadeOverlays: some View {
        VStack(spacing: 0) {
            if model.enableTopFade {
                LinearGradient(
                    colors: [backgroundColor.opacity(model.opacity), backgroundColor.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: model.topFadeHeight)
            }

            Spacer()

            if model.enableBottomFade {
                LinearGradient(
                    colors: [backgroundColor.opacity(0), backgroundColor.opacity(model.opacity)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: model.bottomFadeHeight)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .allowsHitTesting(false)
    }

    private var progressRail: some View {
        HStack {
            Spacer()
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(textColor.opacity(0.16))
                        .frame(width: 4)
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(textColor.opacity(0.62))
                        .frame(width: 4, height: geometry.size.height * model.progress)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(width: 4)
            .padding(.vertical, 12)
            .padding(.trailing, 7)
        }
        .allowsHitTesting(false)
    }

    private var hoverControls: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Button {
                    model.toggleRunning()
                } label: {
                    Image(systemName: model.isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 22))
                }
                .help(model.isRunning ? "Pause" : "Play")

                Button {
                    model.scrollBack()
                } label: {
                    Image(systemName: "backward.circle.fill")
                        .font(.system(size: 22))
                }
                .help("Scroll back")

                Button {
                    openSettingsWindow()
                } label: {
                    Image(systemName: "gearshape.circle.fill")
                        .font(.system(size: 22))
                }
                .help("Open Settings")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.62))
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
            )
            .padding(.bottom, 3)
        }
    }

    private var topCornerControls: some View {
        VStack {
            HStack(spacing: 7) {
                Spacer()

                Button {
                    model.toggleMinimized()
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.black.opacity(0.58)))
                }
                .help("Minimize")

                Button {
                    model.closePrompt()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.black.opacity(0.58)))
                }
                .help("Close")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
            .padding(.top, 10)
            .padding(.trailing, 12)

            Spacer()
        }
    }

    private func handleHover(_ hovering: Bool) {
        guard model.pauseOnHover else {
            wasRunningBeforeHover = false
            return
        }

        if hovering {
            wasRunningBeforeHover = model.isRunning
            if model.isRunning {
                model.pause()
            }
        } else if wasRunningBeforeHover {
            model.start()
            wasRunningBeforeHover = false
        }
    }

    private func openSettingsWindow() {
        AppDelegate.shared?.showSettingsWindow(nil)
    }

    private var focusOpacity: Double {
        showControls || model.isRunning ? 1.0 : 0.72
    }

    private var usesDarkTheme: Bool {
        switch model.theme {
        case .dark: return true
        case .light: return false
        case .auto: return colorScheme == .dark
        }
    }

    private var backgroundColor: Color {
        usesDarkTheme ? Color(red: 0.035, green: 0.038, blue: 0.044) : Color(red: 0.96, green: 0.965, blue: 0.95)
    }

    private var textColor: Color {
        usesDarkTheme ? .white : Color(red: 0.08, green: 0.09, blue: 0.1)
    }

    private var borderColor: Color {
        usesDarkTheme ? .white : .black
    }

    private var accentColor: Color {
        usesDarkTheme ? Color(red: 0.5, green: 0.9, blue: 0.78) : Color(red: 0.0, green: 0.43, blue: 0.56)
    }
}

private struct HeightReader: View {
    var onChange: (Double) -> Void

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    onChange(proxy.size.height)
                }
                .onChange(of: proxy.size) { newSize in
                    onChange(newSize.height)
                }
        }
    }
}

extension Font.Weight {
    init(_ weight: NSFont.Weight) {
        switch weight {
        case .bold: self = .bold
        case .medium: self = .medium
        default: self = .regular
        }
    }
}
