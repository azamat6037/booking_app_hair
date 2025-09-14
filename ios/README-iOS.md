Hairbnb iOS (SwiftUI) — Drop-in MVP

This folder contains SwiftUI source files you can drop into a new Xcode project to get an iPhone app with the same MVP features as the web version: browse, book, my bookings, and hairdresser admin. All data persists in UserDefaults; no backend required.

Quick Setup (Xcode)

1) Open Xcode → Create a new project → iOS → App.
   - Product Name: HairbnbHair
   - Interface: SwiftUI
   - Language: Swift
2) After Xcode creates the project, in Finder or Xcode add the files from `ios/Sources/` into your project (drag the folder into Xcode, “Copy items if needed”).
3) Replace the generated `ContentView.swift` with `RootView.swift` and make sure `HairbnbHairApp.swift` is part of the target.
4) Build & run on an iPhone simulator.

Feature Parity

- Browse hairdressers, search by name/service, and jump to booking.
- Book with date and time slot selection; double-booking prevented.
- My Bookings shows user bookings or, for logged-in hairdresser, all client bookings.
- Admin: login or create account, manage profile, services, and working hours.

Demo Accounts

- Hairdresser 1: fade@example.com / demo
- Hairdresser 2: curl@example.com / demo

Notes

- Time slots are generated every 30 minutes between working hours and single-slot bookings are prevented. Multi-slot blocking by service duration is not implemented in this MVP.
- Storage uses UserDefaults with JSON encoding, mirroring the web’s localStorage approach.
