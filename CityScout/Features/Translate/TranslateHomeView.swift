import SwiftUI
#if canImport(Translation)
import Translation
#endif

struct TranslateHomeView: View {
    @State private var inputText = ""
    @State private var translatedText = ""
    @State private var selectedTargetLanguage: TranslateLanguage = .spanish
    @State private var errorMessage: String?
    @State private var isTranslating = false

#if canImport(Translation)
    @State private var translationConfiguration: TranslationSession.Configuration?
#endif

    var body: some View {
        content
        .navigationTitle("Translate")
    }

    @ViewBuilder
    private var content: some View {
#if canImport(Translation)
        if #available(iOS 18.0, *) {
            translateForm
                .translationTask(translationConfiguration) { session in
                    do {
                        let response = try await session.translate(inputText)
                        await MainActor.run {
                            translatedText = response.targetText
                            isTranslating = false
                            errorMessage = nil
                        }
                    } catch {
                        await MainActor.run {
                            translatedText = ""
                            isTranslating = false
                            errorMessage = "Translation failed. Please try again."
                        }
                    }
                }
        } else {
            unavailableView
        }
#else
        unavailableView
#endif
    }

    private var translateForm: some View {
        Form {
            Section("Input") {
                TextEditor(text: $inputText)
                    .frame(minHeight: 120)
                    .accessibilityLabel("Text to translate")
                    .accessibilityHint("Enter the text you want translated.")
            }

            Section("Target Language") {
                Picker("Target Language", selection: $selectedTargetLanguage) {
                    ForEach(TranslateLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityHint("Choose the language to translate into.")
            }

            Section {
                Button {
                    translate()
                } label: {
                    if isTranslating {
                        HStack {
                            ProgressView()
                            Text("Translating…")
                        }
                    } else {
                        Text("Translate")
                    }
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTranslating)
            }

            Section("Output") {
                if translatedText.isEmpty {
                    Text("Translation will appear here.")
                        .foregroundStyle(.secondary)
                } else {
                    Text(translatedText)
                        .textSelection(.enabled)
                        .accessibilityLabel("Translated text")
                }
            }

            if let errorMessage {
                Section("Status") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var unavailableView: some View {
        ContentUnavailableView(
            "Translation Unavailable",
            systemImage: "exclamationmark.triangle",
            description: Text("Translation requires a newer iOS version.")
        )
        .padding()
    }

    private func translate() {
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }

        translatedText = ""
        errorMessage = nil
        isTranslating = true

#if canImport(Translation)
        if #available(iOS 18.0, *) {
            translationConfiguration = TranslationSession.Configuration(
                source: nil,
                target: selectedTargetLanguage.localeLanguage
            )
        } else {
            isTranslating = false
        }
#else
        isTranslating = false
#endif
    }
}

enum TranslateLanguage: String, CaseIterable, Identifiable {
    case english
    case french
    case spanish

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .french:
            return "French"
        case .spanish:
            return "Spanish"
        }
    }

#if canImport(Translation)
    @available(iOS 18.0, *)
    var localeLanguage: Locale.Language {
        switch self {
        case .english:
            return .init(identifier: "en")
        case .french:
            return .init(identifier: "fr")
        case .spanish:
            return .init(identifier: "es")
        }
    }
#endif
}

#Preview {
    TranslateHomeView()
}
