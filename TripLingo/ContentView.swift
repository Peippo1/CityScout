//
//  ContentView.swift
//  TripLingo
//
//  Created by Tim Finch on 15/02/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                LessonsHomeView()
            }
                .tabItem {
                    Label("Lessons", systemImage: "book")
                }

            NavigationStack {
                PhrasebookHomeView()
            }
                .tabItem {
                    Label("Phrasebook", systemImage: "text.book.closed")
                }

            NavigationStack {
                TranslateHomeView()
            }
                .tabItem {
                    Label("Translate", systemImage: "globe")
                }

            NavigationStack {
                ExploreHomeView()
            }
                .tabItem {
                    Label("Explore", systemImage: "map")
                }
        }
    }
}

#Preview {
    ContentView()
}
