import SwiftUI
#if canImport(Translation)
import Translation
#endif

struct TranslateHomeView: View {
    let destinationName: String

    @State private var inputText = ""
    @State private var submittedText = ""
    @State private var translatedText = ""
    @State private var selectedSourceLanguage: TranslateAppLanguage = .autoDetect
    @State private var selectedTargetLanguage: TranslateAppLanguage = .spanish
    @State private var errorMessage: String?
    @State private var isTranslating = false

#if canImport(Translation)
    @State private var translationConfiguration: TranslationSession.Configuration?
#endif

    var body: some View {
        Group {
#if canImport(Translation)
            if #available(iOS 18.0, *) {
                supportedContent
                    .translationTask(translationConfiguration) { session in
                        await runTranslation(using: session)
                    }
            } else {
                unavailableView
            }
#else
            unavailableView
#endif
        }
        .navigationTitle("\(destinationName) Translate")
    }

    private var supportedContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CityHeaderView(destinationName: destinationName)
                    .padding(.horizontal)
                    .padding(.top, 8)

                introCard
                inputSection
                languageSection
                actionSection
                outputSection
            }
            .padding(.bottom)
        }
        .background(Color.brandCream.ignoresSafeArea())
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Translate short phrases for taxis, cafes, stations, and check-ins.")
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            Text("Use short, practical wording when you need something quickly in the city.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Short phrases work best, such as “Two tickets, please” or “Where is the train station?”")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.brandSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.brandPink.opacity(0.16), lineWidth: 1)
        )
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Phrase to Translate")
                .font(.headline)
                .padding(.horizontal)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.brandSurface)

                if inputText.isEmpty {
                    Text("Type a short travel phrase")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $inputText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 140)
                    .padding(10)
                    .background(Color.clear)
                    .accessibilityLabel("Source text")
                    .accessibilityHint("Enter the phrase you want translated.")
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.brandSage.opacity(0.12), lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Languages")
                .font(.headline)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 14) {
                Picker("From", selection: $selectedSourceLanguage) {
                    ForEach(TranslateAppLanguage.sourceOptions) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .accessibilityLabel("Source language")
                .accessibilityHint("Choose the language you are translating from, or use Auto Detect.")

                Button {
                    swapLanguages()
                } label: {
                    Label("Swap Languages", systemImage: "arrow.up.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Swap source and target languages")
                .accessibilityHint("Swaps the source and target languages and flips translated text into the input when available.")

                Picker("To", selection: $selectedTargetLanguage) {
                    ForEach(TranslateAppLanguage.targetOptions) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .accessibilityLabel("Target language")
                .accessibilityHint("Choose the language you want the phrase translated into.")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.brandSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.brandSage.opacity(0.12), lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                startTranslation()
            } label: {
                HStack {
                    if isTranslating {
                        ProgressView()
                            .accessibilityHidden(true)
                    }

                    Text(isTranslating ? "Translating..." : "Translate")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.brandGreenDark)
            .disabled(trimmedInputText.isEmpty || isTranslating)
            .accessibilityLabel("Translate phrase")
            .accessibilityHint("Starts translation for the current phrase.")

            Button("Clear") {
                clearTranslation()
            }
            .buttonStyle(.bordered)
            .tint(.brandSage)
            .accessibilityHint("Clears the source text, translated text, and any status message.")
        }
        .padding(.horizontal)
    }

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Translation")
                    .font(.headline)

                Spacer()

                if !translatedText.isEmpty {
                    Text(selectedTargetLanguage.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                if isTranslating && translatedText.isEmpty {
                    HStack(spacing: 10) {
                        ProgressView()
                            .accessibilityHidden(true)
                        Text("Working on your translation...")
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else if translatedText.isEmpty {
                    Text("Your translated phrase will appear here.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(translatedText)
                        .textSelection(.enabled)
                        .accessibilityLabel("Translated text")
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .accessibilityLabel("Translation status")
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.brandSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.brandPink.opacity(0.16), lineWidth: 1)
            )
            .padding(.horizontal)
            .accessibilityElement(children: .contain)
        }
    }

    private var trimmedInputText: String {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var unavailableView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                CityHeaderView(destinationName: destinationName)
                    .padding(.horizontal)
                    .padding(.top, 8)

                ContentUnavailableView(
                    "Translation Unavailable",
                    systemImage: "globe",
                    description: Text("Translation requires a supported iOS version.")
                )
                .accessibilityLabel("Translation unavailable")
                .accessibilityHint("This device does not support the translation feature.")
            }
        }
        .background(Color.brandCream.ignoresSafeArea())
    }

    private func swapLanguages() {
        let previousSource = selectedSourceLanguage
        selectedSourceLanguage = selectedTargetLanguage
        selectedTargetLanguage = previousSource.translationLanguage ?? .english

        guard !translatedText.isEmpty else { return }

        let previousInput = inputText
        inputText = translatedText
        translatedText = previousInput
    }

    private func clearTranslation() {
        inputText = ""
        submittedText = ""
        translatedText = ""
        errorMessage = nil
        isTranslating = false

#if canImport(Translation)
        translationConfiguration = nil
#endif
    }

    private func startTranslation() {
        let phrase = trimmedInputText
        guard !phrase.isEmpty else { return }

        submittedText = phrase
        translatedText = ""
        errorMessage = nil
        isTranslating = true

#if canImport(Translation)
        if #available(iOS 18.0, *) {
            updateTranslationConfiguration()
        } else {
            isTranslating = false
        }
#else
        isTranslating = false
#endif
    }

#if canImport(Translation)
    @available(iOS 18.0, *)
    private func updateTranslationConfiguration() {
        if var configuration = translationConfiguration {
            configuration.source = selectedSourceLanguage.localeLanguage
            configuration.target = selectedTargetLanguage.localeLanguage
            configuration.invalidate()
            translationConfiguration = configuration
        } else {
            translationConfiguration = TranslationSession.Configuration(
                source: selectedSourceLanguage.localeLanguage,
                target: selectedTargetLanguage.localeLanguage
            )
        }
    }

    @available(iOS 18.0, *)
    @MainActor
    private func runTranslation(using session: TranslationSession) async {
        guard isTranslating, !submittedText.isEmpty else { return }

        do {
            let response = try await session.translate(submittedText)
            translatedText = response.targetText
            errorMessage = nil
        } catch {
            translatedText = ""
            errorMessage = translationErrorMessage(for: error)
        }

        isTranslating = false
    }

    @available(iOS 18.0, *)
    private func translationErrorMessage(for error: Error) -> String {
        switch error {
        case TranslationError.unsupportedLanguagePairing:
            return "This language pair is not supported right now."
        case TranslationError.unsupportedSourceLanguage:
            return "The selected source language is not supported."
        case TranslationError.unsupportedTargetLanguage:
            return "The selected target language is not supported."
        case TranslationError.unableToIdentifyLanguage:
            return "CityScout could not detect the source language. Try selecting it manually."
        case TranslationError.nothingToTranslate:
            return "Enter a short phrase to translate."
        default:
            return "Translation failed. Please try again."
        }
    }
#endif
}

private enum TranslateAppLanguage: String, CaseIterable, Identifiable {
    case autoDetect
    case english
    case spanish
    case french
    case greek
    case italian
    case finnish
    case danish
    case portuguese

    var id: String { rawValue }

    static var sourceOptions: [TranslateAppLanguage] {
        allCases
    }

    static var targetOptions: [TranslateAppLanguage] {
        allCases.filter { $0 != .autoDetect }
    }

    var displayName: String {
        switch self {
        case .autoDetect:
            return "Auto Detect"
        case .english:
            return "English"
        case .spanish:
            return "Spanish"
        case .french:
            return "French"
        case .greek:
            return "Greek"
        case .italian:
            return "Italian"
        case .finnish:
            return "Finnish"
        case .danish:
            return "Danish"
        case .portuguese:
            return "Portuguese"
        }
    }

#if canImport(Translation)
    @available(iOS 18.0, *)
    var localeLanguage: Locale.Language? {
        switch self {
        case .autoDetect:
            return nil
        case .english:
            return Locale.Language(identifier: "en")
        case .spanish:
            return Locale.Language(identifier: "es")
        case .french:
            return Locale.Language(identifier: "fr")
        case .greek:
            return Locale.Language(identifier: "el")
        case .italian:
            return Locale.Language(identifier: "it")
        case .finnish:
            return Locale.Language(identifier: "fi")
        case .danish:
            return Locale.Language(identifier: "da")
        case .portuguese:
            return Locale.Language(identifier: "pt")
        }
    }
#endif

    var translationLanguage: TranslateAppLanguage? {
        self == .autoDetect ? nil : self
    }
}

#Preview {
    NavigationStack {
        TranslateHomeView(destinationName: "Paris")
    }
}
