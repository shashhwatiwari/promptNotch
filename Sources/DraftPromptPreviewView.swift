import SwiftUI

struct DraftPromptPreviewView: View {
    @ObservedObject var draft: PromptDraft
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .underPageBackgroundColor)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                notch
                prompt
                    .frame(
                        width: min(max(320, draft.promptWidth), 760),
                        height: min(max(78, draft.autoSizeEnabled ? draft.calculatedHeight() : draft.promptHeight), 150)
                    )
            }
            .padding(.top, 16)
        }
    }

    private var notch: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.black)
            .frame(width: 154, height: 28)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(backgroundColor.opacity(draft.opacity))
                    .frame(width: 42, height: 10)
                    .offset(y: 8)
            }
            .shadow(color: .black.opacity(0.18), radius: 10, y: 6)
    }

    private var prompt: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(backgroundColor.opacity(draft.opacity))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(borderColor.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.22), radius: 18, y: 10)

            Text(attributedScript)
                .multilineTextAlignment(.center)
                .lineSpacing(draft.lineSpacing)
                .lineLimit(Int(draft.visibleLines))
                .padding(.horizontal, 24)
                .padding(.vertical, 14)

            if draft.showProgressBar {
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(textColor.opacity(0.52))
                        .frame(width: 4, height: 52)
                        .padding(.trailing, 8)
                }
            }
        }
    }

    private var attributedScript: AttributedString {
        let base = draft.script.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Paste or import a script in Settings..."
            : draft.script
        var attributed = AttributedString(base)
        attributed.font = .system(size: draft.fontSize, weight: Font.Weight(draft.nsFontWeight), design: .rounded)
        attributed.foregroundColor = textColor
        return attributed
    }

    private var usesDarkTheme: Bool {
        switch draft.theme {
        case .dark: return true
        case .light: return false
        case .auto: return colorScheme == .dark
        }
    }

    private var backgroundColor: Color {
        usesDarkTheme ? Color(red: 0.045, green: 0.048, blue: 0.055) : Color(red: 0.96, green: 0.965, blue: 0.95)
    }

    private var textColor: Color {
        usesDarkTheme ? .white : Color(red: 0.07, green: 0.075, blue: 0.085)
    }

    private var borderColor: Color {
        usesDarkTheme ? .white : .black
    }
}
