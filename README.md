# ZamlifT
ZamLift is a full-stack ride-sharing platform focused on inter-city travel where drivers post planned trips and passengers book seats along predefined and AI-optimized routes, with real-time chat, mobile payments, and intelligent route learning.

## Repository Layout

```
ZAMLIFT/
├── backend/   Node.js + Express REST API + Socket.io (see backend/README.md)
└── mobile/    Flutter mobile app (iOS & Android)
```

## Quick Start

### Backend
```bash
cd ZAMLIFT/backend
cp .env.example .env   # fill in DATABASE_URL and JWT_SECRET
npm install
psql "$DATABASE_URL" -f src/sql/schema.sql
npm run dev
```

### Flutter App
```bash
cd ZAMLIFT/mobile
flutter pub get
flutter run
```

> For the Android emulator, the default `baseUrl` is `http://10.0.2.2:5000`.  
> For a physical device, update `ApiConstants.baseUrl` in  
> `lib/core/constants/api_constants.dart` or call `ApiConstants.configure(url)` from `main.dart`.

