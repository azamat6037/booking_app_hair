import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Lightweight auth strip similar to the web topbar
            HStack { AuthMenuView().padding(.horizontal) }
                .padding(.vertical, 8)
                .background(Color(.systemGroupedBackground))
            TabView(selection: $app.currentTab) {
                BrowseView()
                    .tabItem { Label("Browse", systemImage: "magnifyingglass") }
                    .tag(0)
                BookView()
                    .tabItem { Label("Book", systemImage: "calendar") }
                    .tag(1)
                MyBookingsView()
                    .tabItem { Label("My Bookings", systemImage: "list.bullet") }
                    .tag(2)
                AdminView()
                    .tabItem { Label("Admin", systemImage: "person.crop.circle") }
                    .tag(3)
            }
        }
    }
}
