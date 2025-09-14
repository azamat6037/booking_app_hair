import Foundation

struct Service: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var duration: Int // minutes
    var price: Double
}

struct Hours: Codable, Equatable {
    var start: String // "HH:mm"
    var end: String   // "HH:mm"
}

struct Hairdresser: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var email: String
    var password: String
    var location: String
    var services: [Service]
    var hours: Hours
}

struct Booking: Identifiable, Codable, Equatable {
    var id: UUID
    var userName: String
    var hairdresserId: UUID
    var service: String
    var date: String // YYYY-MM-DD
    var time: String // HH:mm
    var createdAt: Date
}

struct Session: Codable, Equatable {
    enum Kind: String, Codable { case guest, user, hairdresser }
    var type: Kind
    var name: String?
    var email: String?
    var hairdresserId: UUID?

    static var guest: Session { .init(type: .guest, name: "Guest", email: nil, hairdresserId: nil) }
    var isHairdresser: Bool { type == .hairdresser }
}

