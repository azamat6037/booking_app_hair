# Hairbnb — Hairdresser Booking MVP

A minimal, client‑only MVP to book hairdresser appointments. No backend required — all data is stored in your browser via localStorage.

## Run

- Open `index.html` in a browser.
- That’s it. The app seeds two sample hairdressers you can book with immediately.

## Demo Accounts

- Hairdresser 1: `fade@example.com` / `demo`
- Hairdresser 2: `curl@example.com` / `demo`

## Features

- Browse hairdressers: name, location, services and prices.
- Book as guest or with a simple name login.
- Time slots auto‑generated every 30 minutes within hairdresser working hours.
- Prevent double‑booking for the same time slot.
- View "My Bookings" (for user/guest) or all bookings (for logged‑in hairdresser).
- Hairdresser admin can:
  - Update profile (name, location) and working hours.
  - Add/remove services (name, duration, price).
  - See their upcoming bookings.

## Data Model (localStorage)

- `hb_hairdressers`: array of hairdressers `{ id, name, email, password, location, services[], hours { start, end } }`
- `hb_bookings`: array of bookings `{ id, userName, hairdresserId, service, date, time, createdAt }`
- `hb_session`: current session `{ type: 'guest'|'user'|'hairdresser', name?, email?, hairdresserId? }`

Note: This MVP treats each slot as 30 minutes regardless of the service duration. It prevents booking the same start time but does not span multi‑slot blocking yet.

## Project Layout

- `index.html`: Single‑page app with four views (Browse, Book, My Bookings, Admin).
- `assets/styles.css`: Minimal styling.
- `assets/app.js`: App logic, localStorage persistence, UI behavior.

## Next Steps

- Span time blocking to match service durations across multiple slots.
- Add simple availability calendar per hairdresser.
- Export/import data (JSON) for persistence beyond one browser.
- Replace localStorage with a backend API when needed.
