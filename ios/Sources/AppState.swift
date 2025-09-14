import Foundation
import SwiftUI

final class AppState: ObservableObject {
    @Published var hairdressers: [Hairdresser] = []
    @Published var bookings: [Booking] = []
    @Published var session: Session = .guest

    // UI state
    @Published var currentTab: Int = 0 // 0 Browse, 1 Book, 2 MyBookings, 3 Admin
    @Published var searchQuery: String = ""
    @Published var selectedHairdresserId: UUID? = nil

    init() {
        load()
        seedIfEmpty()
    }

    func load() {
        hairdressers = Store.load(.hairdressers, as: [Hairdresser].self) ?? []
        bookings = Store.load(.bookings, as: [Booking].self) ?? []
        session = Store.load(.session, as: Session.self) ?? .guest
    }
    func saveHairdressers() { Store.save(.hairdressers, hairdressers) }
    func saveBookings() { Store.save(.bookings, bookings) }
    func saveSession() { Store.save(.session, session) }

    func seedIfEmpty() {
        guard hairdressers.isEmpty else { return }
        let a = Hairdresser(
            id: UUID(),
            name: "Fade & Blade",
            email: "fade@example.com",
            password: "demo",
            location: "Downtown",
            services: [
                Service(name: "Men Haircut", duration: 30, price: 30),
                Service(name: "Beard Trim", duration: 20, price: 15)
            ],
            hours: Hours(start: "09:00", end: "18:00")
        )
        let b = Hairdresser(
            id: UUID(),
            name: "Curl & Care",
            email: "curl@example.com",
            password: "demo",
            location: "Uptown",
            services: [
                Service(name: "Wash & Style", duration: 45, price: 40),
                Service(name: "Coloring", duration: 90, price: 120)
            ],
            hours: Hours(start: "10:00", end: "17:30")
        )
        hairdressers = [a, b]
        saveHairdressers()
    }

    func hairdresser(by id: UUID?) -> Hairdresser? {
        guard let id = id else { return nil }
        return hairdressers.first { $0.id == id }
    }

    func serviceNames(for h: Hairdresser) -> [String] { h.services.map { $0.name } }

    func filteredHairdressers() -> [Hairdresser] {
        let q = searchQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return hairdressers }
        return hairdressers.filter { h in
            h.name.lowercased().contains(q) ||
            h.location.lowercased().contains(q) ||
            h.services.contains { $0.name.lowercased().contains(q) }
        }
    }

    func bookedTimes(for hid: UUID, on date: String) -> Set<String> {
        Set(bookings.filter { $0.hairdresserId == hid && $0.date == date }.map { $0.time })
    }

    func book(hairdresserId: UUID, service: String, date: String, time: String) -> Bool {
        let taken = bookedTimes(for: hairdresserId, on: date)
        guard !taken.contains(time) else { return false }
        let userName: String
        switch session.type {
        case .user: userName = session.name ?? "Guest"
        case .guest: userName = "Guest"
        case .hairdresser: userName = session.email ?? "Client"
        }
        let booking = Booking(id: UUID(), userName: userName, hairdresserId: hairdresserId, service: service, date: date, time: time, createdAt: Date())
        bookings.append(booking)
        saveBookings()
        return true
    }
}

