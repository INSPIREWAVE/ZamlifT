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
