import SwiftUI

struct AuthMenuView: View {
    @EnvironmentObject var app: AppState
    @State private var userName: String = ""

    var body: some View {
        HStack {
            Text(currentUserLabel).foregroundStyle(.secondary)
            Spacer()
            if app.session.type == .guest {
                TextField("Your name", text: $userName)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)
                Button("Use Name") { loginUser() }
            } else {
                Button("Logout") { app.session = .guest; app.saveSession() }
            }
        }
    }

    var currentUserLabel: String {
        switch app.session.type {
        case .guest: return "Guest"
        case .user: return app.session.name ?? "User"
        case .hairdresser:
            if let n = app.hairdresser(by: app.session.hairdresserId)?.name { return n }
            return "Admin"
        }
    }

    func loginUser() {
        let name = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { return }
        app.session = Session(type: .user, name: name, email: nil, hairdresserId: nil)
        app.saveSession()
    }
}

