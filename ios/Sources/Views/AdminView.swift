import SwiftUI

struct AdminView: View {
    @EnvironmentObject var app: AppState
    @State private var loginEmail: String = ""
    @State private var loginPassword: String = ""

    // Profile fields
    @State private var name: String = ""
    @State private var location: String = ""
    @State private var startHour: String = "09:00"
    @State private var endHour: String = "18:00"

    // Service fields
    @State private var svcName: String = ""
    @State private var svcDuration: String = ""
    @State private var svcPrice: String = ""

    // Registration fields
    @State private var regName: String = ""
    @State private var regEmail: String = ""
    @State private var regPassword: String = ""
    @State private var regLocation: String = ""

    var isLoggedIn: Bool { app.session.isHairdresser }
    var currentHairdresser: Hairdresser? {
        app.hairdresser(by: app.session.hairdresserId)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !isLoggedIn {
                        GroupBox("Login as Hairdresser") {
                            VStack(alignment: .leading) {
                                TextField("Email", text: $loginEmail).textInputAutocapitalization(.never).textFieldStyle(.roundedBorder)
                                SecureField("Password", text: $loginPassword).textFieldStyle(.roundedBorder)
                                HStack {
                                    Spacer()
                                    Button("Login") { login() }.buttonStyle(.borderedProminent)
                                }
                            }
                        }
                        GroupBox("Create Hairdresser Account") {
                            VStack(alignment: .leading) {
                                TextField("Business name", text: $regName).textFieldStyle(.roundedBorder)
                                TextField("Email", text: $regEmail).textInputAutocapitalization(.never).textFieldStyle(.roundedBorder)
                                SecureField("Password", text: $regPassword).textFieldStyle(.roundedBorder)
                                TextField("Location", text: $regLocation).textFieldStyle(.roundedBorder)
                                HStack { Spacer(); Button("Create Account") { register() } }
                            }
                        }
                    } else if let h = currentHairdresser {
                        GroupBox("Profile") {
                            VStack(alignment: .leading) {
                                TextField("Name", text: $name).textFieldStyle(.roundedBorder)
                                TextField("Location", text: $location).textFieldStyle(.roundedBorder)
                                HStack { Spacer(); Button("Save Profile") { saveProfile() } }
                            }
                        }
                        GroupBox("Services") {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    TextField("Service name", text: $svcName).textFieldStyle(.roundedBorder)
                                    TextField("Duration (min)", text: $svcDuration).textFieldStyle(.roundedBorder).frame(width: 120)
                                    TextField("Price", text: $svcPrice).textFieldStyle(.roundedBorder).frame(width: 100)
                                    Button("Add") { addService() }
                                }
                                if h.services.isEmpty {
                                    Text("No services yet").foregroundStyle(.secondary)
                                } else {
                                    ForEach(h.services) { s in
                                        HStack {
                                            Text("\(s.name) · \(s.duration)m · $\(Int(s.price))")
                                            Spacer()
                                            Button(role: .destructive) { removeService(s) } label: { Image(systemName: "trash") }
                                        }.padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                        GroupBox("Working Hours") {
                            HStack {
                                TextField("Start (HH:mm)", text: $startHour).textFieldStyle(.roundedBorder)
                                TextField("End (HH:mm)", text: $endHour).textFieldStyle(.roundedBorder)
                                Spacer()
                                Button("Save Hours") { saveHours() }
                            }
                            Text("Slots are generated every 30 minutes.").font(.footnote).foregroundStyle(.secondary)
                        }
                        HStack { Spacer(); Button("Logout") { logout() }.buttonStyle(.bordered) }
                    }
                }
                .padding()
            }
            .navigationTitle("Hairdresser Admin")
        }
        .onAppear { syncFromModel() }
    }

    // Actions
    func login() {
        let email = loginEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let pass = loginPassword
        guard let h = app.hairdressers.first(where: { $0.email.lowercased() == email && $0.password == pass }) else { return }
        app.session = Session(type: .hairdresser, name: nil, email: email, hairdresserId: h.id)
        app.saveSession()
        syncFromModel()
    }
    func register() {
        let email = regEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !regName.isEmpty, !email.isEmpty, !regPassword.isEmpty else { return }
        guard !app.hairdressers.contains(where: { $0.email.lowercased() == email }) else { return }
        let h = Hairdresser(id: UUID(), name: regName, email: email, password: regPassword, location: regLocation, services: [], hours: Hours(start: "09:00", end: "18:00"))
        app.hairdressers.append(h)
        app.saveHairdressers()
        regName = ""; regEmail = ""; regPassword = ""; regLocation = ""
    }
    func saveProfile() {
        guard let hid = app.session.hairdresserId, let idx = app.hairdressers.firstIndex(where: {$0.id == hid}) else { return }
        app.hairdressers[idx].name = name
        app.hairdressers[idx].location = location
        app.saveHairdressers()
    }
    func saveHours() {
        guard let hid = app.session.hairdresserId, let idx = app.hairdressers.firstIndex(where: {$0.id == hid}) else { return }
        app.hairdressers[idx].hours = Hours(start: startHour, end: endHour)
        app.saveHairdressers()
    }
    func addService() {
        guard let hid = app.session.hairdresserId, let idx = app.hairdressers.firstIndex(where: {$0.id == hid}) else { return }
        guard !svcName.isEmpty, let dur = Int(svcDuration) else { return }
        let price = Double(svcPrice) ?? 0
        app.hairdressers[idx].services.append(Service(name: svcName, duration: dur, price: price))
        app.saveHairdressers()
        svcName = ""; svcDuration = ""; svcPrice = ""
    }
    func removeService(_ svc: Service) {
        guard let hid = app.session.hairdresserId, let idx = app.hairdressers.firstIndex(where: {$0.id == hid}) else { return }
        app.hairdressers[idx].services.removeAll { $0.id == svc.id }
        app.saveHairdressers()
    }
    func logout() {
        app.session = .guest
        app.saveSession()
    }

    func syncFromModel() {
        if let h = currentHairdresser {
            name = h.name
            location = h.location
            startHour = h.hours.start
            endHour = h.hours.end
        }
    }
}

