import SwiftUI

struct TranslateHomeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick translation and explanation tools will appear here.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle("Translate")
    }
}

#Preview {
    TranslateHomeView()
}
