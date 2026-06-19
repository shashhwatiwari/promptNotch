import SwiftUI
import UniformTypeIdentifiers

struct ControlView: View {
    @ObservedObject var model: TeleprompterModel
    @ObservedObject var draft: PromptDraft
    @State private var isImporterPresented = false
    @FocusState private var isScriptEditorFocused: Bool

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.plainText, .text, .utf8PlainText, .markdownText],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                try? draft.importScript(from: url)
            }
        }
        .onChange(of: draft.mode) { _ in
            draft.applyModePreset()
        }
        .onChange(of: draft.visibleLines) { _ in
            syncAutoHeight()
        }
        .onChange(of: draft.fontSize) { _ in
            syncAutoHeight()
        }
        .onChange(of: draft.lineSpacing) { _ in
            syncAutoHeight()
        }
        .onChange(of: draft.autoSizeEnabled) { _ in
            syncAutoHeight()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Notch Teleprompter")
                    .font(.title2.weight(.semibold))
                Text("\(draft.wordCount) words • \(durationText)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Picker("Mode", selection: $draft.mode) {
                ForEach(PromptMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 10) {
                Button {
                    applyDraft()
                } label: {
                    Label("Apply", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }

                Button {
                    draft.reload(from: model)
                } label: {
                    Label("Revert", systemImage: "arrow.uturn.backward")
                }
            }
            .buttonStyle(.borderedProminent)

            Divider()

            GroupBox("Prompt") {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle("Click-through after apply", isOn: $draft.isClickThrough)
                    Toggle("Pause on hover", isOn: $draft.pauseOnHover)
                    Toggle("Hover controls", isOn: $draft.showHoverControls)
                    Toggle("Progress bar", isOn: $draft.showProgressBar)
                    Picker("Position", selection: $draft.position) {
                        ForEach(PromptPosition.allCases) { position in
                            Text(position.rawValue).tag(position)
                        }
                    }
                    Picker("Theme", selection: $draft.theme) {
                        ForEach(PromptTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            GroupBox("Pacing") {
                VStack(alignment: .leading, spacing: 12) {
                    valueSlider("Words per minute", value: $draft.wpm, range: 80...220, step: 5, suffix: "WPM")
                    ProgressView(value: model.progress)
                }
                .padding(.vertical, 4)
            }

            GroupBox("Appearance") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Auto-size height", isOn: $draft.autoSizeEnabled)
                    valueSlider("Visible lines", value: $draft.visibleLines, range: 1...7, step: 1, suffix: "lines")
                    valueSlider("Width", value: $draft.promptWidth, range: 320...980, step: 10, suffix: "px")
                    valueSlider("Height", value: $draft.promptHeight, range: 72...420, step: 6, suffix: "px")
                        .disabled(draft.autoSizeEnabled)
                    valueSlider("Font size", value: $draft.fontSize, range: 14...44, step: 1, suffix: "pt")
                    valueSlider("Line spacing", value: $draft.lineSpacing, range: 0...20, step: 1, suffix: "px")
                    valueSlider("Opacity", value: $draft.opacity, range: 0.25...1, step: 0.05, suffix: "")
                    valueSlider("Weight", value: $draft.textWeight, range: 0...1, step: 0.5, suffix: draft.textWeightName)
                    Toggle("Top fade", isOn: $draft.enableTopFade)
                    Toggle("Bottom fade", isOn: $draft.enableBottomFade)
                }
                .padding(.vertical, 4)
            }

            Spacer()
        }
        .padding(20)
        .navigationSplitViewColumnWidth(min: 320, ideal: 360)
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Preview")
                        .font(.title3.weight(.semibold))

                    Spacer()

                    Button {
                        applyDraft()
                    } label: {
                        Label("Apply", systemImage: "checkmark")
                    }

                    Button {
                        applyDraft()
                        NSApp.keyWindow?.performClose(nil)
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                }

                DraftPromptPreviewView(draft: draft)
                    .frame(height: 190)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(nsColor: .separatorColor))
                    )
            }

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
                    draft.script = ""
                } label: {
                    Label("Clear", systemImage: "trash")
                }
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .textBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(
                                isScriptEditorFocused ? Color.accentColor : Color(nsColor: .separatorColor),
                                lineWidth: isScriptEditorFocused ? 2 : 1
                            )
                    )
                    .shadow(color: .black.opacity(0.03), radius: 1, y: 1)

                if draft.script.isEmpty {
                    Text("Type your script here...\n\nUse [brackets] for stage directions like [pause], [smile], or [gesture].")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $draft.script)
                    .font(.system(size: 17, weight: .regular, design: .default))
                    .lineSpacing(5)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isScriptEditorFocused)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
            }
        }
        .padding(22)
    }

    private var durationText: String {
        let seconds = Int(draft.estimatedDuration.rounded())
        return "\(seconds / 60)m \(seconds % 60)s at \(Int(draft.wpm)) WPM"
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

        if suffix == draft.textWeightName {
            return suffix
        }

        return "\(Int(value.rounded())) \(suffix)"
    }

    private func applyDraft() {
        syncAutoHeight()
        model.apply(from: draft)
    }

    private func syncAutoHeight() {
        if draft.autoSizeEnabled {
            draft.promptHeight = draft.calculatedHeight()
        }
    }
}

private extension UTType {
    static var markdownText: UTType {
        UTType(filenameExtension: "md") ?? .plainText
    }
}
