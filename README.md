# ZamLift

ZamLift is a full-stack ride-sharing platform focused on inter-city travel where drivers post planned trips and passengers book seats along predefined and AI-optimized routes, with real-time chat, mobile payments, and intelligent route learning.

## Repository Layout

```
├── backend/          Node.js + Express + PostgreSQL API (JWT auth, trips, bookings, payments, ratings, Socket.io, admin, smart suggestions)
├── mobile/           Flutter mobile client (auth, trip search, booking, chat — initial scaffold)
├── admin/            React dashboard for monitoring users, driver approvals, trips, and payments
└── ZAMLIFT/
    ├── backend/      Production-hardened backend with security, logic, and data-integrity fixes
    └── mobile/       Complete Flutter app wired to every backend endpoint
```

## Quick Start

### Backend (`ZAMLIFT/backend/` — recommended, fully fixed)
```bash
cd ZAMLIFT/backend
cp .env.example .env   # fill in DATABASE_URL and JWT_SECRET
npm install
psql "$DATABASE_URL" -f src/sql/schema.sql
npm run dev
```

### Flutter App (`ZAMLIFT/mobile/` — complete client)
```bash
cd ZAMLIFT/mobile
flutter pub get
flutter run
```

> For the Android emulator the default `baseUrl` is `http://10.0.2.2:5000`.  
> For a physical device update `ApiConstants.baseUrl` in  
> `lib/core/constants/api_constants.dart` or call `ApiConstants.configure(url)` from `main.dart`.

### Backend (`backend/` — original scaffold)
```bash
cd backend
cp .env.example .env
npm install
npm run dev
```

### Admin Dashboard
```bash
cd admin
npm install
# optionally: VITE_API_BASE_URL=http://localhost:4000/api VITE_ADMIN_JWT=<token>
npm run dev
```

## Security & Architecture Highlights

- JWT authentication + role-based access (`passenger`, `driver`, `admin`)
- Validation via Joi / Zod
- Security middleware (Helmet, CORS, rate limiting)
- Centralised error handling
- Modular route-based architecture
- PostgreSQL relational schema with foreign keys and indexes
