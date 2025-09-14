import SwiftUI

struct BrowseView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    TextField("Search by name or service", text: $app.searchQuery)
                        .textFieldStyle(.roundedBorder)
                    Button("Clear") { app.searchQuery = "" }
                        .buttonStyle(.borderedProminent)
                }

                List(app.filteredHairdressers()) { h in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(h.name).font(.headline)
                            Spacer()
                            Text(h.location).foregroundStyle(.secondary)
                        }
                        if h.services.isEmpty {
                            Text("No services yet").foregroundStyle(.secondary).font(.subheadline)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack { ForEach(h.services) { s in
                                    Text("\(s.name) · $\(Int(s.price))")
                                        .font(.footnote).padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Color.gray.opacity(0.15)).clipShape(Capsule())
                                } }
                            }
                        }
                        HStack { Spacer() }
                        HStack {
                            Spacer()
                            Button("Book") {
                                app.selectedHairdresserId = h.id
                                app.currentTab = 1
                            }.buttonStyle(.bordered)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .padding()
            .navigationTitle("Find a Hairdresser")
        }
    }
}

