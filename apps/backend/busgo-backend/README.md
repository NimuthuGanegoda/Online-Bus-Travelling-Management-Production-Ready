# BusGo Backend API

Production-ready **Express.js** REST API for the BusGo Sri Lankan (Colombo) bus management application.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Runtime | Node.js ≥ 18 |
| Framework | Express.js 4 |
| Database | Supabase (PostgreSQL) via `@supabase/supabase-js` |
| Auth | JWT (access 15 min + refresh 7 days) + bcrypt |
| Validation | Zod |
| Security | Helmet, CORS, express-rate-limit |
| Logging | Morgan (HTTP) + Winston (app) |
| File uploads | Supabase Storage (avatars) |
| Real-time | Supabase Realtime broadcast (bus locations) |

---

## Quick Start

### 1. Prerequisites
- Node.js ≥ 18
- A [Supabase](https://supabase.com) project

### 2. Clone & install

```bash
# from the repo root
npm run install:backend
# or directly:
cd apps/backend/busgo-backend
npm install
```

### 3. Configure environment

```bash
cp .env.example .env
# Edit .env with your values (see table below)
```

You only need to fill in the 3 Supabase values (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`). The JWT secrets in `.env.example` are pre-generated and safe for development; rotate them for production.

### 4. Set up Supabase database

In your Supabase dashboard, go to **SQL Editor** and run the following files **in order**:

1. `src/db/full_setup.sql`         — base schema, admin schema, seed data (routes 138/163/171, stops, buses, demo user, admins)
2. `src/db/driver_migration.sql`   — driver app: adds `password_hash` to drivers, `driver_id` to alerts, `accident` enum value
3. `src/db/payments_migration.sql` — payments module additions

### 5. Create Supabase Storage bucket

In your Supabase dashboard → **Storage** → **New bucket**:
- Name: `avatars`
- Public: ✅ (check "Public bucket")

### 6. Run the server

```bash
# Development (auto-reload via nodemon)
npm run dev

# Production
npm start
```

Server starts at: `http://localhost:5000`
Health check:     `http://localhost:5000/health`

---

## 🔑 Demo Credentials (after seed)

The SQL seed scripts create these accounts so you can hit the API immediately.

### Passenger (mobile app — `users` table)

| Email | Password |
|---|---|
| `admin@gmail.com` | `12345678` |

### Driver (driver app — `drivers` table)

Drivers can log in with **email** OR **driver code**. Default password = the driver code itself, until they change it.

| Email | Code | Password | Status |
|---|---|---|---|
| `kamal@busgo.lk` | `DRV-001` | `DRV-001` | active |
| `saman@busgo.lk` | `DRV-002` | `DRV-002` | active |
| `amara@busgo.lk` | `DRV-005` | `DRV-005` | active |
| `nimal@busgo.lk` | `DRV-003` | `DRV-003` | inactive (login blocked) |
| `ruwan@busgo.lk` | `DRV-004` | `DRV-004` | pending approval |

### Admin (admin web dashboard — `admins` table)

| Email | Password | Role |
|---|---|---|
| `admin@busgo.lk` | `Admin@2026` | super_admin |
| `kasun@busgo.lk` | `Admin@2026` | admin |
| `dilani@busgo.lk` | `Admin@2026` | admin |

> ⚠️ **Change every password before going to production.**

---

## Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `NODE_ENV` | No | `development` | `development` \| `production` \| `test` |
| `PORT` | No | `5000` | HTTP server port |
| `SUPABASE_URL` | **Yes** | — | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | **Yes** | — | Supabase anon public key |
| `SUPABASE_SERVICE_ROLE_KEY` | **Yes** | — | Supabase service role key (never expose to clients) |
| `JWT_ACCESS_SECRET` | **Yes** | — | Min 32 chars. Generate: `node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"` |
| `JWT_REFRESH_SECRET` | **Yes** | — | Min 32 chars |
| `JWT_RESET_SECRET` | **Yes** | — | Min 32 chars |
| `JWT_ACCESS_EXPIRES_IN` | No | `900` | Access token TTL in seconds (15 min) |
| `JWT_REFRESH_EXPIRES_IN` | No | `604800` | Refresh token TTL in seconds (7 days) |
| `JWT_RESET_EXPIRES_IN` | No | `300` | Reset token TTL in seconds (5 min) |
| `BCRYPT_ROUNDS` | No | `12` | bcrypt cost factor (10–14) |
| `RATE_LIMIT_AUTH_WINDOW_MS` | No | `900000` | Auth rate limit window (ms) |
| `RATE_LIMIT_AUTH_MAX` | No | `10` | Max auth requests per window |
| `RATE_LIMIT_GENERAL_WINDOW_MS` | No | `60000` | General rate limit window (ms) |
| `RATE_LIMIT_GENERAL_MAX` | No | `100` | Max general requests per window |
| `QR_TOKEN_EXPIRES_SECONDS` | No | `30` | QR card token TTL (30 s, matches Flutter app) |
| `RESET_PIN_EXPIRES_MINUTES` | No | `10` | Password reset PIN TTL |
| `SUPABASE_STORAGE_AVATARS_BUCKET` | No | `avatars` | Supabase Storage bucket name |
| `CORS_ORIGINS` | No | `http://localhost:3000` | Comma-separated allowed origins |

---

## API Endpoints

All endpoints return the standard response shape:
```json
{
  "success": true,
  "message": "Human-readable message",
  "data": {},
  "pagination": {}
}
```

### AUTH  `/api/auth`

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/register` | ❌ | Register new user |
| POST | `/login` | ❌ | Login with email + password |
| POST | `/logout` | ❌ | Revoke refresh token |
| POST | `/refresh` | ❌ | Exchange refresh token for new pair |
| POST | `/forgot-password/request` | ❌ | Send reset PIN (logged to console) |
| POST | `/forgot-password/verify` | ❌ | Verify PIN → get reset_token |
| POST | `/forgot-password/reset` | ❌ | Set new password using reset_token |

**Demo credentials:** `admin@gmail.com` / `12345678`

**Register body:**
```json
{
  "email": "user@example.com",
  "password": "mypassword123",
  "full_name": "John Doe",
  "username": "johndoe",
  "phone": "+94771234567",
  "membership_type": "standard"
}
```

**Login response:**
```json
{
  "data": {
    "user": { "id": "...", "email": "...", "full_name": "..." },
    "access_token": "eyJ...",
    "refresh_token": "eyJ..."
  }
}
```

---

### USERS  `/api/users`  🔒

| Method | Endpoint | Description |
|---|---|---|
| GET | `/me` | Get own profile |
| PATCH | `/me` | Update profile (name, username, phone, DOB) |
| PATCH | `/me/avatar` | Upload avatar (multipart/form-data, field: `avatar`) |
| GET | `/me/preferences` | Get notification preferences |
| PATCH | `/me/preferences` | Update notification preferences |
| GET | `/me/stats` | Total trips, total spent, average rating |

---

### QR CARD  `/api/qr`  🔒

| Method | Endpoint | Description |
|---|---|---|
| GET | `/my-card` | Get current QR token (auto-refreshes after 30 s) |
| POST | `/scan-exit` | Scan out of bus → completes trip + prompts rating |

---

### BUSES  `/api/buses`

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/nearby?lat=&lng=&radius=` | ❌ | Buses within radius (km) sorted by distance |
| GET | `/:id` | ❌ | Get bus with route details |
| PATCH | `/:id/location` | 🔒 | Driver updates GPS position |
| PATCH | `/:id/crowd` | 🔒 | Driver updates crowd level |

**Bus location update body:**
```json
{ "lat": 6.9000, "lng": 79.8800, "heading": 315.0, "speed_kmh": 35.0 }
```

---

### BUS ROUTES  `/api/routes`

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/` | ❌ | All active routes |
| GET | `/search?q=` | ❌ | Search by number/name/origin/destination |
| GET | `/:id` | ❌ | Route details + waypoints |
| GET | `/:id/stops` | ❌ | Ordered stops on route |
| GET | `/:id/buses` | ❌ | Active buses on route |

---

### BUS STOPS  `/api/stops`

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/` | ❌ | All stops |
| GET | `/nearby?lat=&lng=&radius=` | ❌ | Stops within radius |
| GET | `/:id` | ❌ | Stop details + routes |
| GET | `/:id/routes` | ❌ | Routes through stop |

---

### TRIPS  `/api/trips`  🔒

| Method | Endpoint | Description |
|---|---|---|
| GET | `/?status=&from=&to=&page=&page_size=` | Paginated trip history |
| GET | `/:id` | Trip details with rating |
| POST | `/` | Start trip (board bus) |
| PATCH | `/:id/alight` | End trip (exit bus) |

**Start trip body:**
```json
{ "bus_id": "uuid", "route_id": "uuid", "boarding_stop_id": "uuid" }
```

---

### RATINGS  `/api/ratings`  🔒

| Method | Endpoint | Description |
|---|---|---|
| GET | `/` | My submitted ratings |
| POST | `/` | Rate a completed trip |
| GET | `/bus/:busId` | Average rating stats for a bus |

**Create rating body:**
```json
{
  "trip_id": "uuid",
  "bus_id": "uuid",
  "stars": 5,
  "tags": ["Punctual", "Friendly"],
  "comment": "Great ride!"
}
```

---

### EMERGENCY  `/api/emergency`  🔒

| Method | Endpoint | Description |
|---|---|---|
| GET | `/` | My emergency alerts |
| POST | `/` | Send new emergency alert |
| PATCH | `/:id/status` | Update alert status |

**Alert types:** `medical` | `criminal` | `breakdown` | `harassment` | `other`

**Create alert body:**
```json
{
  "alert_type": "medical",
  "description": "Passenger collapsed on the bus",
  "latitude": 6.9000,
  "longitude": 79.8800
}
```

---

### NOTIFICATIONS  `/api/notifications`  🔒

| Method | Endpoint | Description |
|---|---|---|
| GET | `/?category=&unread_only=&page=` | Paginated notifications |
| PATCH | `/:id/read` | Mark single notification as read |
| PATCH | `/read-all` | Mark all as read |
| DELETE | `/:id` | Delete a notification |

**Categories:** `bus_alert` | `trip` | `emergency` | `payment` | `general`

---

### RECENT SEARCHES  `/api/searches/recent`  🔒

| Method | Endpoint | Description |
|---|---|---|
| GET | `/` | Get last 5 searches |
| POST | `/` | Save a search query |
| DELETE | `/` | Clear all searches |

---

## Supabase Setup Instructions

### 1. Create a new Supabase project
1. Go to [supabase.com](https://supabase.com) → **New project**
2. Choose a region close to Sri Lanka (e.g., Singapore `ap-southeast-1`)
3. Set a strong database password

### 2. Run schema
Go to **SQL Editor** → **New query** → paste `src/db/schema.sql` → **Run**

### 3. Run seed data
Go to **SQL Editor** → **New query** → paste `src/db/seed.sql` → **Run**

### 4. Get API keys
**Settings** → **API**:
- `SUPABASE_URL` = Project URL
- `SUPABASE_ANON_KEY` = `anon` `public` key
- `SUPABASE_SERVICE_ROLE_KEY` = `service_role` key (**keep secret**)

### 5. Create storage bucket
**Storage** → **New bucket** → Name: `avatars` → Enable **Public bucket** → **Save**

### 6. Enable Realtime for bus locations
**Database** → **Replication** → Enable replication on the `buses` table.
The API uses the Supabase Realtime broadcast channel `bus-locations` for driver location updates.

---

## Authentication Flow

```
POST /api/auth/register → { access_token, refresh_token }
POST /api/auth/login    → { access_token, refresh_token }

# Use access_token in all protected requests:
Authorization: Bearer <access_token>

# When access_token expires (15 min):
POST /api/auth/refresh  body: { refresh_token } → { access_token, refresh_token }

# Forgot password:
POST /api/auth/forgot-password/request  body: { email }       → PIN logged to console
POST /api/auth/forgot-password/verify   body: { email, pin }  → { reset_token }
POST /api/auth/forgot-password/reset    body: { reset_token, new_password, confirm_password }
```

---

## Rate Limiting

| Scope | Limit |
|---|---|
| `/api/auth/*` | 10 requests / 15 minutes per IP |
| All other `/api/*` | 100 requests / minute per user (or IP if unauthenticated) |

---

## Project Structure

```
src/
├── app.js                    ← Express app setup
├── server.js                 ← HTTP server entry point
├── config/
│   ├── env.js                ← Zod-validated env vars
│   ├── supabase.js           ← Supabase service-role client
│   └── constants.js          ← App-wide constants
├── db/
│   ├── schema.sql            ← Full PostgreSQL schema + RLS
│   └── seed.sql              ← Seed data (routes, stops, buses, demo user)
├── middleware/
│   ├── auth.middleware.js    ← JWT Bearer verification
│   ├── validate.middleware.js← Zod schema validation factory
│   ├── error.middleware.js   ← Global error + 404 handlers
│   └── rateLimiter.middleware.js
├── modules/
│   ├── auth/                 ← Register, login, logout, refresh, forgot-password
│   ├── users/                ← Profile, avatar, preferences, stats
│   ├── qr/                   ← QR card generation + scan-exit
│   ├── buses/                ← Nearby buses, location & crowd updates
│   ├── routes/               ← Bus route CRUD + search
│   ├── stops/                ← Bus stop CRUD + nearby
│   ├── trips/                ← Trip lifecycle (board → alight)
│   ├── ratings/              ← Driver ratings
│   ├── emergency/            ← Emergency alerts
│   ├── notifications/        ← Notification management
│   └── searches/             ← Recent searches (max 5)
└── utils/
    ├── jwt.utils.js          ← Token signing + verification
    ├── password.utils.js     ← bcrypt hash + compare
    ├── pin.utils.js          ← Reset PIN generation + verification
    ├── haversine.utils.js    ← GPS distance calculation
    ├── response.utils.js     ← Standard response shape helpers
    └── logger.js             ← Winston logger
```

---

## License

MIT — BusGo Team
