import SwiftUI

struct BookView: View {
    @EnvironmentObject var app: AppState
    @State private var selectedService: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: String = ""
    @State private var message: String? = nil
    @State private var isError: Bool = false

    var selectedHairdresser: Hairdresser? {
        if let id = app.selectedHairdresserId { return app.hairdresser(by: id) }
        return app.hairdressers.first
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Hairdresser") {
                    Picker("Hairdresser", selection: Binding(
                        get: { app.selectedHairdresserId ?? app.hairdressers.first?.id },
                        set: { app.selectedHairdresserId = $0 }
                    )) {
                        ForEach(app.hairdressers) { h in
                            Text(h.name).tag(Optional(h.id))
                        }
                    }
                }
                Section("Service") {
                    Picker("Service", selection: $selectedService) {
                        ForEach(selectedHairdresser?.services ?? []) { s in
                            Text("\(s.name) · $\(Int(s.price))").tag(s.name)
                        }
                    }
                }
                Section("Date & Time") {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .onChange(of: selectedDate) { _ in updateTimes() }
                    Picker("Time", selection: $selectedTime) {
                        ForEach(availableTimes(), id: \.self) { t in
                            Text(t)
                        }
                    }
                }
                Section { Button("Book") { submit() } }
                if let msg = message { Section { Text(msg).foregroundStyle(isError ? .red : .green) } }
            }
            .navigationTitle("Book an Appointment")
            .onAppear {
                if selectedService.isEmpty { selectedService = selectedHairdresser?.services.first?.name ?? "" }
                updateTimes()
            }
        }
    }

    func availableTimes() -> [String] {
        guard let h = selectedHairdresser else { return [] }
        let date = dateToYMD(selectedDate)
        let all = generateSlots(start: h.hours.start, end: h.hours.end, step: 30)
        let taken = app.bookedTimes(for: h.id, on: date)
        let free = all.filter { !taken.contains($0) }
        if selectedTime.isEmpty { selectedTime = free.first ?? "" }
        return free
    }

    func updateTimes() { _ = availableTimes() }

    func submit() {
        guard let hid = selectedHairdresser?.id, !selectedService.isEmpty, !selectedTime.isEmpty else {
            message = "Please fill all fields"; isError = true; return
        }
        let ok = app.book(hairdresserId: hid, service: selectedService, date: dateToYMD(selectedDate), time: selectedTime)
        if ok { message = "Booked successfully!"; isError = false; app.currentTab = 2 }
        else { message = "Selected time already booked"; isError = true }
    }
}

