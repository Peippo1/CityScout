import SwiftUI

struct ExploreHomeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Destination-specific cultural notes and tips will appear here.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle("Explore")
    }
}

#Preview {
    ExploreHomeView()
}
