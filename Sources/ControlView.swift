import SwiftUI
import UniformTypeIdentifiers

struct ControlView: View {
    @ObservedObject var model: TeleprompterModel
    @State private var isImporterPresented = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            editor
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.plainText, .text, .utf8PlainText, .markdownText],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                try? model.importScript(from: url)
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Notch Teleprompter")
                    .font(.title2.weight(.semibold))
                Text("\(model.wordCount) words • \(durationText)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Picker("Mode", selection: $model.mode) {
                ForEach(PromptMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 10) {
                Button {
                    model.toggleRunning()
                } label: {
                    Label(model.isRunning ? "Pause" : "Start", systemImage: model.isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.space, modifiers: [])

                Button {
                    model.reset()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
            }
            .buttonStyle(.borderedProminent)

            Divider()

            GroupBox("Prompt") {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle("Show overlay", isOn: $model.isPromptVisible)
                    Toggle("Click-through", isOn: $model.isClickThrough)
                    Picker("Position", selection: $model.position) {
                        ForEach(PromptPosition.allCases) { position in
                            Text(position.rawValue).tag(position)
                        }
                    }
                    Picker("Theme", selection: $model.theme) {
                        ForEach(PromptTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            GroupBox("Pacing") {
                VStack(alignment: .leading, spacing: 12) {
                    valueSlider("Words per minute", value: $model.wpm, range: 80...220, step: 5, suffix: "WPM")
                    ProgressView(value: model.progress)
                }
                .padding(.vertical, 4)
            }

            GroupBox("Appearance") {
                VStack(alignment: .leading, spacing: 12) {
                    valueSlider("Width", value: $model.promptWidth, range: 360...980, step: 10, suffix: "px")
                    valueSlider("Height", value: $model.promptHeight, range: 72...360, step: 6, suffix: "px")
                    valueSlider("Font size", value: $model.fontSize, range: 14...44, step: 1, suffix: "pt")
                    valueSlider("Line spacing", value: $model.lineSpacing, range: 0...20, step: 1, suffix: "px")
                    valueSlider("Opacity", value: $model.opacity, range: 0.25...1, step: 0.05, suffix: "")
                    valueSlider("Weight", value: $model.textWeight, range: 0...1, step: 0.5, suffix: model.textWeightName)
                }
                .padding(.vertical, 4)
            }

            Spacer()
        }
        .padding(20)
        .navigationSplitViewColumnWidth(min: 320, ideal: 360)
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Script")
                    .font(.title3.weight(.semibold))

                Spacer()

                Button {
                    isImporterPresented = true
                } label: {
                    Label("Import", systemImage: "doc.badge.plus")
                }

                Button {
                    model.script = ""
                    model.reset()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
            }

            TextEditor(text: $model.script)
                .font(.system(size: 17, weight: .regular, design: .default))
                .lineSpacing(5)
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor))
                )
        }
        .padding(22)
    }

    private var durationText: String {
        let seconds = Int(model.estimatedDuration.rounded())
        return "\(seconds / 60)m \(seconds % 60)s at \(Int(model.wpm)) WPM"
    }

    private func valueSlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        suffix: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(label(for: value.wrappedValue, suffix: suffix))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step)
        }
        .font(.callout)
    }

    private func label(for value: Double, suffix: String) -> String {
        if suffix.isEmpty {
            return String(format: "%.2f", value)
        }

        if suffix == model.textWeightName {
            return suffix
        }

        return "\(Int(value.rounded())) \(suffix)"
    }
}

private extension UTType {
    static var markdownText: UTType {
        UTType(filenameExtension: "md") ?? .plainText
    }
}
