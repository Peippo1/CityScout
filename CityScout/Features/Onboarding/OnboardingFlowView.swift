import SwiftUI
import Combine

struct OnboardingFlowView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let timer = Timer.publish(every: 2.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: $currentPage) {
                OnboardingPageView(
                    title: "Learn Key Phrases Offline",
                    message: "Study practical travel phrases even without internet.",
                    symbolName: "book.closed"
                )
                .tag(0)

                OnboardingPageView(
                    title: "Explore by City",
                    message: "Browse destinations and useful places before your trip.",
                    symbolName: "airplane.departure"
                )
                .tag(1)

                OnboardingPageView(
                    title: "Save What Matters",
                    message: "Keep phrases and places handy while you are on the move.",
                    symbolName: "mappin.and.ellipse"
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut(duration: 0.4), value: currentPage)

            if currentPage == 2 {
                Button("Get Started") {
                    hasSeenOnboarding = true
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Get started")
                .accessibilityHint("Finishes onboarding and opens destination selection.")
            }
        }
        .padding()
        .onReceive(timer) { _ in
            guard currentPage < 2 else { return }
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPage += 1
            }
        }
    }
}

private struct OnboardingPageView: View {
    let title: String
    let message: String
    let symbolName: String

    @State private var animateIcon = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: symbolName)
                .font(.system(size: 72))
                .foregroundStyle(.accent)
                .scaleEffect(animateIcon ? 1.0 : 0.88)
                .opacity(animateIcon ? 1.0 : 0.7)
                .accessibilityHidden(true)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                animateIcon = true
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OnboardingFlowView()
}
