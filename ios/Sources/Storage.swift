import Foundation

enum StoreKey: String { case hairdressers = "hb_hairdressers", bookings = "hb_bookings", session = "hb_session" }

struct Store {
    static func load<T: Decodable>(_ key: StoreKey, as type: T.Type) -> T? {
        UserDefaults.standard.data(forKey: key.rawValue)
            .flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }
    static func save<T: Encodable>(_ key: StoreKey, _ value: T) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key.rawValue)
        }
    }
}

func dateToYMD(_ date: Date) -> String {
    let df = DateFormatter()
    df.calendar = Calendar(identifier: .gregorian)
    df.locale = Locale(identifier: "en_US_POSIX")
    df.dateFormat = "yyyy-MM-dd"
    return df.string(from: date)
}

func todayYMD() -> String { dateToYMD(Date()) }

func timeToMinutes(_ hhmm: String) -> Int {
    let comps = hhmm.split(separator: ":").compactMap { Int($0) }
    guard comps.count == 2 else { return 0 }
    return comps[0] * 60 + comps[1]
}

func minutesToTime(_ minutes: Int) -> String {
    let h = String(format: "%02d", minutes / 60)
    let m = String(format: "%02d", minutes % 60)
    return "\(h):\(m)"
}

func generateSlots(start: String, end: String, step: Int = 30) -> [String] {
    let s = timeToMinutes(start)
    let e = timeToMinutes(end)
    guard e > s else { return [] }
    var out: [String] = []
    var t = s
    while t + step <= e { out.append(minutesToTime(t)); t += step }
    return out
}

