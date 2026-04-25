import SwiftUI

struct GuideHomeView: View {
    private struct GuideMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
    }

    private enum GuideState {
        case idle
        case loading
        case error(String)
    }

    private let starterPrompts = [
        "What should I know about this city?",
        "What are some interesting facts nearby?",
        "What local food should I try?",
        "Give me a short walking tour idea",
    ]

    let destinationName: String

    @State private var inputText = ""
    @State private var messages: [GuideMessage] = []
    @State private var state: GuideState = .idle
    @State private var suggestedPrompts: [String] = []

    private let guideAPIService = GuideAPIService()

    var body: some View {
        VStack(spacing: 0) {
            CityHeaderView(destinationName: destinationName)
                .padding(.horizontal)
                .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Ask your CityScout guide about places, history, food, culture, or what to see next in \(destinationName).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    starterPromptSection

                    if messages.isEmpty {
                        ContentUnavailableView(
                            "Start a conversation",
                            systemImage: "text.bubble",
                            description: Text("Send a message to get practical, city-aware tips.")
                        )
                    } else {
                        ForEach(messages) { message in
                            messageBubble(message)
                        }
                    }

                    if case .loading = state {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Your CityScout guide is thinking…")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.brandSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    if case .error(let message) = state {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding()
            }

            composerBar
        }
        .navigationTitle("Guide")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var composerBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Ask your guide…", text: $inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1 ... 4)

            Button("Send") {
                Task {
                    await sendMessage(inputText)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    private var displayedPrompts: [String] {
        suggestedPrompts.isEmpty ? starterPrompts : suggestedPrompts
    }

    @ViewBuilder
    private var starterPromptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Try asking:")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(displayedPrompts, id: \.self) { prompt in
                Button(prompt) {
                    Task {
                        await sendMessage(prompt)
                    }
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func messageBubble(_ message: GuideMessage) -> some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 40)
            }

            Text(message.text)
                .font(.body)
                .padding(12)
                .foregroundStyle(message.isUser ? Color.white : Color.primary)
                .background(
                    message.isUser
                        ? Color.accentColor
                        : Color.brandSurface,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )

            if !message.isUser {
                Spacer(minLength: 40)
            }
        }
    }

    @MainActor
    private func sendMessage(_ rawMessage: String) async {
        let message = rawMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard message.isEmpty == false, isLoading == false else { return }

        inputText = ""
        state = .loading
        messages.append(GuideMessage(text: message, isUser: true))

        do {
            let response = try await guideAPIService.sendMessage(
                destination: destinationName,
                message: message,
                context: []
            )
            messages.append(GuideMessage(text: response.reply, isUser: false))
            suggestedPrompts = response.suggestedPrompts
            state = .idle
        } catch {
            state = .error("Guide is temporarily unavailable. Please try again in a moment.")
        }
    }
}

#Preview {
    NavigationStack {
        GuideHomeView(destinationName: "Paris")
    }
}
