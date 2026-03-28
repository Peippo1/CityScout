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
            .accessibilityLabel("Onboarding pages")
            .accessibilityHint("Swipe left or right to review CityScout features.")

            if currentPage == 2 {
                Button("Get Started") {
                    hasSeenOnboarding = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.brandGreenDark)
                .accessibilityLabel("Get started")
                .accessibilityHint("Finishes onboarding and opens destination selection.")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.brandCream, Color.brandSurface, Color.brandPink.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
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
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brandSage.opacity(0.28), Color.brandPink.opacity(0.22)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 128, height: 128)

                Image(systemName: symbolName)
                    .font(.system(size: 72, weight: .regular, design: .default))
                    .foregroundStyle(Color.brandGreenDark)
                    .scaleEffect(animateIcon ? 1.0 : 0.88)
                    .opacity(animateIcon ? 1.0 : 0.7)
                    .accessibilityHidden(true)
            }

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.brandSage.opacity(0.14), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                animateIcon = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

#Preview {
    OnboardingFlowView()
}
