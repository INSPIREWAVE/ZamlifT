# ZamLift

## Backend (ZamLift)

Path: `/home/runner/work/ZamlifT/ZamlifT/ZAMLIFT/backend`

### Setup

1. Copy env file:
   - `cp .env.example .env`
2. Update `.env` with your PostgreSQL and JWT values.
3. Create DB schema:
   - `psql "$DATABASE_URL" -f src/sql/schema.sql`
4. Install deps:
   - `npm install`
5. Run API:
   - `npm run dev`

### Scripts

- `npm run dev` - start with nodemon
- `npm start` - start production server
- `npm run check` - syntax check for all backend source files

---

## API Reference

> All routes are prefixed with `/api`.  
> Protected routes require `Authorization: Bearer <token>` header.  
> Request bodies use **camelCase**. Responses use **snake\_case** (direct DB rows).

### Auth

| Method | Path | Auth | Body / Query | Response |
|--------|------|------|--------------|----------|
| POST | `/auth/register` | — | `{fullName, email, password, role: "passenger"\|"driver"}` | `{user, token}` |
| POST | `/auth/login` | — | `{email, password}` | `{user, token}` |

`user` shape: `{id, full_name, email, role, is_active, created_at}`

---

### Drivers

| Method | Path | Auth | Body / Query | Response |
|--------|------|------|--------------|----------|
| POST | `/drivers/profile` | driver | `{licenseNumber, nationalId, phone}` | driver\_profile |
| POST | `/drivers/vehicle` | driver | `{make, model, year, plateNumber, seatCapacity}` | vehicle |
| GET | `/drivers/pending` | admin | — | `[driver_profile + full_name, email]` |
| PATCH | `/drivers/:driverId/verify` | admin | `{status: "approved"\|"rejected"}` | driver\_profile |

`driver_profile` shape: `{user_id, license_number, national_id, phone, verification_status, average_rating, total_ratings, verified_by, verified_at, created_at, updated_at}`

`vehicle` shape: `{id, driver_id, make, model, year, plate_number, seat_capacity, created_at, updated_at}`

---

### Routes & Stops

| Method | Path | Auth | Body / Query | Response |
|--------|------|------|--------------|----------|
| POST | `/routes` | admin | `{name, originCity, destinationCity, baseDistanceKm}` | route |
| GET | `/routes` | — | — | `[route]` |
| POST | `/routes/:routeId/stops` | admin | `{name, city, latitude, longitude, sequenceOrder}` | `{stop, routeStop}` |
| GET | `/routes/:routeId/stops` | — | — | `[stop + sequence_order, route_id]` |

`route` shape: `{id, name, origin_city, destination_city, base_distance_km, created_at, updated_at}`

`stop` shape: `{id, name, city, latitude, longitude, popularity_score, created_at, updated_at}`

---

### Trips

| Method | Path | Auth | Body / Query | Response |
|--------|------|------|--------------|----------|
| POST | `/trips` | driver (approved) | `{vehicleId, routeId, departureTime, seatsTotal, pricePerSeat}` | trip |
| GET | `/trips/search` | — | `?fromStopId=&toStopId=&departureDate=YYYY-MM-DD` | `[trip + route_name, origin_city, destination_city, driver_name]` |
| GET | `/trips/:tripId` | — | — | trip (with joined fields) |
| PATCH | `/trips/:tripId/status` | auth (driver or admin) | `{status: "scheduled"\|"ongoing"\|"completed"\|"cancelled"}` | trip |

`trip` shape: `{id, driver_id, vehicle_id, route_id, departure_time, seats_total, seats_available, price_per_seat, status, created_at, updated_at}`

---

### Bookings

| Method | Path | Auth | Body / Query | Response |
|--------|------|------|--------------|----------|
| POST | `/bookings` | auth | `{tripId, pickupStopId, dropoffStopId, seatsBooked}` | booking |
| GET | `/bookings/my` | auth | — | `[booking + departure_time, trip_status, route_name]` |
| PATCH | `/bookings/:bookingId/status` | auth | `{status: "pending"\|"confirmed"\|"cancelled"\|"completed"}` | booking |

`booking` shape: `{id, trip_id, passenger_id, pickup_stop_id, dropoff_stop_id, seats_booked, total_price, status, payment_status, created_at, updated_at}`

---

### Payments

| Method | Path | Auth | Body / Query | Response |
|--------|------|------|--------------|----------|
| POST | `/payments/deposit` | auth (owner) | `{bookingId, amount, phoneNumber}` | payment |
| GET | `/payments/my` | auth | — | `[payment]` |
| GET | `/payments` | admin | — | `[payment]` |
| PATCH | `/payments/:paymentId/status` | admin | `{status: "pending"\|"completed"\|"failed"}` | payment |

`payment` shape: `{id, booking_id, payer_id, amount, provider, reference, phone_number, status, created_at, updated_at}`

When `status` is set to `completed`, the related booking's `payment_status` becomes `paid` and `status` becomes `confirmed`.

---

### Ratings

| Method | Path | Auth | Body / Query | Response |
|--------|------|------|--------------|----------|
| POST | `/ratings` | auth (passenger, completed booking) | `{tripId, rating: 1-5, comment?: string}` | rating |
| GET | `/ratings/driver/:driverId` | — | — | `[rating + passenger_name]` |

`rating` shape: `{id, trip_id, driver_id, passenger_id, rating, comment, created_at}`

Constraints: trip must have `status = 'completed'`; caller must have a completed booking on that trip.

---

### Smart (AI)

| Method | Path | Auth | Body / Query | Response |
|--------|------|------|--------------|----------|
| GET | `/smart/stops` | — | `?query=<text>` | `[stop]` ordered by popularity |
| GET | `/smart/pricing` | — | `?routeId=<uuid>` | `{routeId, suggestedPricePerSeat, historicalBookingCount}` |

---

### Chat (REST)

| Method | Path | Auth | Response |
|--------|------|------|----------|
| GET | `/chat/trips/:tripId/messages` | auth (participant or admin) | `[{id, trip_id, sender_id, message, sender_name, created_at}]` |

---

### Chat (Socket.io)

Connect to the backend root URL. Authenticate via:
```js
io(baseUrl, { auth: { token: "<JWT>" } })
```

| Event (client → server) | Payload | Description |
|-------------------------|---------|-------------|
| `trip:join` | `{ tripId }` | Join a trip room |
| `trip:message` | `{ tripId, message }` | Send a chat message |

| Event (server → client) | Payload | Description |
|-------------------------|---------|-------------|
| `trip:joined` | `{ tripId }` | Confirmed room join |
| `trip:new-message` | `ChatMessage + sender_name` | New message broadcast |
| `trip:error` | `{ message }` | Error from server |

---

### Health

```
GET /api/health  →  { "status": "ok", "service": "zamlift-backend" }
```

