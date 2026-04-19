# ZamLift Mobile App

Flutter app for the ZamLift inter-city ride-sharing platform.

## Setup

```bash
flutter pub get
flutter run
```

### Targeting the backend

Edit `lib/core/constants/api_constants.dart` and change `baseUrl`:

| Target | Value |
|--------|-------|
| Android emulator → host machine | `http://10.0.2.2:5000` (default) |
| iOS simulator → host machine | `http://127.0.0.1:5000` |
| Physical device (same WiFi) | `http://<your-machine-ip>:5000` |

Or call `ApiConstants.configure(url)` at the top of `main()`.

## Architecture

```
lib/
├── main.dart               Entry point; wires providers
├── app.dart                MaterialApp, routes, root gate
├── core/
│   ├── constants/
│   │   └── api_constants.dart    All API URLs
│   ├── network/
│   │   └── api_client.dart       HTTP wrapper with JWT auth
│   ├── storage/
│   │   └── token_storage.dart    Secure token persistence
│   ├── models/                   Dart classes mirroring DB rows
│   └── services/                 One service per domain (auth, trips…)
└── features/
    ├── auth/                     Login & Register screens
    ├── home/                     Dashboard
    ├── trips/                    Search & Trip detail
    ├── bookings/                 My Bookings & detail
    ├── payments/                 Mobile money deposit
    ├── driver/                   Driver profile & vehicle
    ├── chat/                     Real-time trip chat (Socket.io)
    ├── ratings/                  Rate a driver
    └── smart/                    Smart stop autocomplete
```

## API Contract Summary

See `../backend/README.md` for the complete API reference.

### Request field naming

All **request bodies** use `camelCase` keys (the backend validators use `camelCase`):

```jsonc
// POST /api/auth/register
{ "fullName": "Alice", "email": "alice@example.com",
  "password": "secure123", "role": "passenger" }

// POST /api/trips
{ "vehicleId": "uuid", "routeId": "uuid",
  "departureTime": "2025-12-01T08:00:00.000Z",
  "seatsTotal": 4, "pricePerSeat": 250.00 }

// POST /api/bookings
{ "tripId": "uuid", "pickupStopId": "uuid",
  "dropoffStopId": "uuid", "seatsBooked": 2 }

// POST /api/payments/deposit
{ "bookingId": "uuid", "amount": 500.00, "phoneNumber": "+260977000000" }
```

### Response field naming

All **responses** use `snake_case` keys (raw DB rows):

```jsonc
// POST /api/auth/login → 200
{ "user": { "id": "uuid", "full_name": "Alice", "email": "...",
            "role": "passenger", "is_active": true },
  "token": "<JWT>" }

// GET /api/trips/search → 200
[{ "id": "uuid", "driver_id": "...", "departure_time": "...",
   "seats_available": 3, "price_per_seat": "250.00", "status": "scheduled",
   "route_name": "Lusaka–Ndola", "origin_city": "Lusaka",
   "destination_city": "Ndola", "driver_name": "Bob" }]
```

### Socket.io (chat)

```dart
// Connect
final socket = io(ApiConstants.baseUrl, OptionBuilder()
  .setAuth({'token': jwt})
  .setTransports(['websocket'])
  .build());

// Join trip room
socket.emit('trip:join', {'tripId': tripId});

// Send message
socket.emit('trip:message', {'tripId': tripId, 'message': 'On my way!'});

// Receive messages
socket.on('trip:new-message', (data) { /* ChatMessage JSON */ });

// Errors from server
socket.on('trip:error', (data) { /* {message: String} */ });
```
