CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role VARCHAR(20) NOT NULL CHECK (role IN ('passenger', 'driver', 'admin')),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS driver_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  license_number VARCHAR(100) NOT NULL UNIQUE,
  national_id VARCHAR(100) NOT NULL UNIQUE,
  phone VARCHAR(20) NOT NULL,
  verification_status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'approved', 'rejected')),
  average_rating NUMERIC(3,2) NOT NULL DEFAULT 0,
  total_ratings INT NOT NULL DEFAULT 0,
  verified_by UUID REFERENCES users(id),
  verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  make VARCHAR(80) NOT NULL,
  model VARCHAR(80) NOT NULL,
  year INT NOT NULL CHECK (year >= 1980),
  plate_number VARCHAR(30) NOT NULL UNIQUE,
  seat_capacity INT NOT NULL CHECK (seat_capacity > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(120) NOT NULL UNIQUE,
  origin_city VARCHAR(80) NOT NULL,
  destination_city VARCHAR(80) NOT NULL,
  base_distance_km NUMERIC(10,2) NOT NULL CHECK (base_distance_km > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS stops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(120) NOT NULL,
  city VARCHAR(80) NOT NULL,
  latitude NUMERIC(10,7) NOT NULL,
  longitude NUMERIC(10,7) NOT NULL,
  popularity_score INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (name, city)
);

CREATE TABLE IF NOT EXISTS route_stops (
  route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  stop_id UUID NOT NULL REFERENCES stops(id) ON DELETE CASCADE,
  sequence_order INT NOT NULL CHECK (sequence_order > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (route_id, stop_id),
  UNIQUE (route_id, sequence_order)
);

CREATE TABLE IF NOT EXISTS trips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE RESTRICT,
  route_id UUID NOT NULL REFERENCES routes(id) ON DELETE RESTRICT,
  departure_time TIMESTAMPTZ NOT NULL,
  seats_total INT NOT NULL CHECK (seats_total > 0),
  seats_available INT NOT NULL CHECK (seats_available >= 0),
  price_per_seat NUMERIC(10,2) NOT NULL CHECK (price_per_seat > 0),
  status VARCHAR(20) NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'on_trip', 'completed', 'cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  passenger_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pickup_stop_id UUID NOT NULL REFERENCES stops(id) ON DELETE RESTRICT,
  dropoff_stop_id UUID NOT NULL REFERENCES stops(id) ON DELETE RESTRICT,
  seats_booked INT NOT NULL CHECK (seats_booked > 0),
  total_price NUMERIC(10,2) NOT NULL CHECK (total_price >= 0),
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
  payment_status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  payer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
  provider VARCHAR(80) NOT NULL,
  reference VARCHAR(120) NOT NULL UNIQUE,
  phone_number VARCHAR(20) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS earnings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL UNIQUE REFERENCES trips(id) ON DELETE CASCADE,
  driver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  total_revenue NUMERIC(12,2) NOT NULL CHECK (total_revenue >= 0),
  calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS trip_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS driver_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  driver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  passenger_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (trip_id, passenger_id)
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);
CREATE INDEX IF NOT EXISTS idx_driver_profiles_status ON driver_profiles (verification_status);
CREATE INDEX IF NOT EXISTS idx_vehicles_driver_id ON vehicles (driver_id);
CREATE INDEX IF NOT EXISTS idx_route_stops_route_order ON route_stops (route_id, sequence_order);
CREATE INDEX IF NOT EXISTS idx_stops_popularity ON stops (popularity_score DESC);
CREATE INDEX IF NOT EXISTS idx_trips_route_departure ON trips (route_id, departure_time);
CREATE INDEX IF NOT EXISTS idx_trips_driver ON trips (driver_id);
CREATE INDEX IF NOT EXISTS idx_bookings_trip ON bookings (trip_id);
CREATE INDEX IF NOT EXISTS idx_bookings_trip_payment_status ON bookings (trip_id, payment_status, status);
CREATE INDEX IF NOT EXISTS idx_bookings_passenger ON bookings (passenger_id);
CREATE INDEX IF NOT EXISTS idx_payments_booking ON payments (booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_payer ON payments (payer_id);
CREATE INDEX IF NOT EXISTS idx_earnings_driver ON earnings (driver_id);
CREATE INDEX IF NOT EXISTS idx_trip_messages_trip_time ON trip_messages (trip_id, created_at);
CREATE INDEX IF NOT EXISTS idx_driver_ratings_driver ON driver_ratings (driver_id);
