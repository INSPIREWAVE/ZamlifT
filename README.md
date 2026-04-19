# ZamLift

ZamLift is a modular full-stack ride-sharing platform for inter-city travel.

## Project Structure

- `/backend` – Node.js + Express + PostgreSQL API (JWT auth, trips, routes/stops, booking, payments, ratings, realtime Socket.io, admin endpoints, smart suggestions)
- `/mobile` – Flutter mobile client screens/services for auth, trip search, booking, and chat flows
- `/admin` – React dashboard for monitoring users, driver approvals, trips, and payments

## Backend (Node.js + Express + PostgreSQL)

### Setup

1. Copy env config:
   - `cp /home/runner/work/ZamlifT/ZamlifT/backend/.env.example /home/runner/work/ZamlifT/ZamlifT/backend/.env`
2. Create the database and run schema:
   - Apply `/home/runner/work/ZamlifT/ZamlifT/backend/src/db/schema.sql`
3. Install dependencies:
   - `cd /home/runner/work/ZamlifT/ZamlifT/backend && npm install`
4. Start API:
   - `npm run dev` (development)
   - `npm start` (production)

### Core API Groups

- `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/auth/me`
- `POST /api/drivers/profile`, `POST /api/drivers/vehicle`, `PATCH /api/drivers/:id/approve`
- `POST /api/routes`, `POST /api/routes/:routeId/stops`, `GET /api/routes`, `GET /api/routes/popular-stops`
- `POST /api/trips`, `GET /api/trips/search`, `PATCH /api/trips/:id/status`
- `POST /api/bookings`, `GET /api/bookings/me`, `PATCH /api/bookings/:id/status`
- `POST /api/payments/deposit`, `GET /api/payments/:bookingId`
- `POST /api/ratings`, `GET /api/ratings/driver/:driverId`
- `GET /api/admin/users`, `GET /api/admin/drivers/pending`, `GET /api/admin/trips`, `GET /api/admin/payments`
- `GET /api/smart/suggestions`

### Realtime Events (Socket.io)

- `trip:join`, `trip:status_updated`
- `chat:join`, `chat:message`

## Mobile App (Flutter)

> Note: Flutter SDK is required locally. In this environment, `flutter` CLI is unavailable, so files were scaffolded manually.

### Setup

1. Install Flutter SDK.
2. `cd /home/runner/work/ZamlifT/ZamlifT/mobile`
3. `flutter pub get`
4. `flutter run --dart-define=API_BASE_URL=http://localhost:4000/api --dart-define=SOCKET_URL=http://localhost:4000`

## Admin Dashboard (React)

### Setup

1. `cd /home/runner/work/ZamlifT/ZamlifT/admin`
2. `npm install`
3. Optionally create `.env`:
   - `VITE_API_BASE_URL=http://localhost:4000/api`
   - `VITE_ADMIN_JWT=<admin-jwt-token>`
4. Run dashboard:
   - `npm run dev`

## Security & Architecture Highlights

- JWT authentication + role-based access (`passenger`, `driver`, `admin`)
- Validation via Joi
- Security middleware (Helmet, CORS, rate limiting)
- Centralized error handling
- Modular route-based architecture
- PostgreSQL relational schema with foreign keys and indexes
