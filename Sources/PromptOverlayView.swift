import SwiftUI

struct PromptOverlayView: View {
    @ObservedObject var model: TeleprompterModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(backgroundColor.opacity(model.opacity))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(borderColor.opacity(0.28), lineWidth: 1)
                )

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    scrollingText
                        .frame(width: geometry.size.width - 36, alignment: .topLeading)
                        .offset(y: -model.scrollOffset)
                        .animation(.linear(duration: 0.08), value: model.scrollOffset)
                    Spacer(minLength: 0)
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                .clipped()
                .overlay(alignment: .center) {
                    Rectangle()
                        .fill(accentColor.opacity(0.22))
                        .frame(height: 2)
                        .padding(.horizontal, 16)
                }
                .overlay(alignment: .bottomTrailing) {
                    Text("\(Int((model.progress * 100).rounded()))%")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(textColor.opacity(0.55))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
            }
            .padding(.vertical, 12)
        }
        .frame(minWidth: 320, minHeight: 64)
    }

    private var scrollingText: some View {
        Text(model.script)
            .font(.system(size: model.fontSize, weight: Font.Weight(model.nsFontWeight), design: .default))
            .lineSpacing(model.lineSpacing)
            .foregroundStyle(textColor)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, model.promptHeight * 0.42)
            .padding(.bottom, model.promptHeight)
    }

    private var usesDarkTheme: Bool {
        switch model.theme {
        case .dark: return true
        case .light: return false
        case .auto: return colorScheme == .dark
        }
    }

    private var backgroundColor: Color {
        usesDarkTheme ? Color(red: 0.04, green: 0.045, blue: 0.05) : Color(red: 0.96, green: 0.965, blue: 0.95)
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

private extension Font.Weight {
    init(_ weight: NSFont.Weight) {
        switch weight {
        case .bold: self = .bold
        case .medium: self = .medium
        default: self = .regular
        }
    }
}
