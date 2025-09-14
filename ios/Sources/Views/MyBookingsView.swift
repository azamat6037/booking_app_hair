import SwiftUI

struct MyBookingsView: View {
    @EnvironmentObject var app: AppState

    var items: [Booking] {
        switch app.session.type {
        case .hairdresser:
            if let hid = app.session.hairdresserId {
                return app.bookings.filter { $0.hairdresserId == hid }
                    .sorted { ($0.date, $0.time) < ($1.date, $1.time) }
            }
            return []
        case .user:
            let name = app.session.name ?? "Guest"
            return app.bookings.filter { $0.userName == name }
                .sorted { ($0.date, $0.time) < ($1.date, $1.time) }
        case .guest:
            return app.bookings.filter { $0.userName == "Guest" }
                .sorted { ($0.date, $0.time) < ($1.date, $1.time) }
        }
    }

    var body: some View {
        NavigationStack {
            if items.isEmpty {
                ContentUnavailableView("No bookings yet", systemImage: "calendar")
            } else {
                List(items) { b in
                    VStack(alignment: .leading) {
                        Text(b.service).font(.headline)
                        HStack {
                            Text("\(b.date) at \(b.time)")
                            Spacer()
                            if let h = app.hairdressers.first(where: { $0.id == b.hairdresserId }) {
                                Text(h.name).foregroundStyle(.secondary)
                            }
                        }.font(.subheadline)
                        if app.session.isHairdresser { Text("Client: \(b.userName)").foregroundStyle(.secondary) }
                    }
                }.listStyle(.plain)
            }
        }.navigationTitle("My Bookings")
    }
}

