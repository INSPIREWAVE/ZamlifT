const { z } = require('zod');

const uuid = z.string().uuid();
const maxVehicleYear = new Date().getUTCFullYear() + 2;
const TRIP_STATUS_VALUES = ['scheduled', 'on_trip', 'completed', 'cancelled'];

const authRegisterSchema = z.object({
  body: z.object({
    fullName: z
      .string({ required_error: 'Full name is required' })
      .trim()
      .min(1, 'Full name is required')
      .max(100),
    email: z
      .string({ required_error: 'Email is required' })
      .trim()
      .min(1, 'Email is required')
      .email('Email is invalid'),
    password: z
      .string({ required_error: 'Password is required' })
      .min(1, 'Password is required')
      .min(8, 'Password must be at least 8 characters')
      .max(72),
    role: z.enum(['passenger', 'driver'], {
      required_error: 'Role is required',
    }),
    phone: z
      .string({ required_error: 'Phone is required' })
      .trim()
      .nonempty('Phone is required')
      .min(7, 'Phone must be at least 7 characters')
      .max(20, 'Phone must be at most 20 characters'),
  }),
  params: z.object({}).optional(),
  query: z.object({}).optional(),
});

const authLoginSchema = z.object({
  body: z.object({
    email: z.string().email(),
    password: z.string().min(8).max(72),
  }),
  params: z.object({}).optional(),
  query: z.object({}).optional(),
});

const driverProfileSchema = z.object({
  body: z.object({
    licenseNumber: z.string().min(4),
    nationalId: z.string().min(4),
    phone: z.string().min(7).max(20),
  }),
  params: z.object({}).optional(),
  query: z.object({}).optional(),
});

const vehicleSchema = z.object({
  body: z.object({
    make: z.string().min(2),
    model: z.string().min(1),
    year: z.number().int().min(1980).max(maxVehicleYear),
    plateNumber: z.string().min(3),
    seatCapacity: z.number().int().min(1).max(100),
  }),
  params: z.object({}).optional(),
  query: z.object({}).optional(),
});

const verifyDriverSchema = z.object({
  params: z.object({ driverId: uuid }),
  body: z.object({
    status: z.enum(['approved', 'rejected']),
  }),
  query: z.object({}).optional(),
});

const createRouteSchema = z.object({
  body: z.object({
    name: z.string().min(3),
    originCity: z.string().min(2),
    destinationCity: z.string().min(2),
    baseDistanceKm: z.number().positive(),
  }),
  params: z.object({}).optional(),
  query: z.object({}).optional(),
});

const addStopSchema = z.object({
  params: z.object({ routeId: uuid }),
  body: z.object({
    name: z.string().min(2),
    city: z.string().min(2),
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
    sequenceOrder: z.number().int().min(1),
  }),
  query: z.object({}).optional(),
});

const routeIdSchema = z.object({
  params: z.object({ routeId: uuid }),
  body: z.object({}).optional(),
  query: z.object({}).optional(),
});

const createTripSchema = z.object({
  body: z.object({
    vehicleId: uuid,
    routeId: uuid,
    departureTime: z.string().datetime(),
    seatsTotal: z.number().int().min(1).max(100),
    pricePerSeat: z.number().positive(),
  }),
  params: z.object({}).optional(),
  query: z.object({}).optional(),
});

const searchTripsSchema = z.object({
  query: z.object({
    fromStopId: uuid,
    toStopId: uuid,
    departureDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  }),
  body: z.object({}).optional(),
  params: z.object({}).optional(),
});

const tripIdSchema = z.object({
  params: z.object({ tripId: uuid }),
  body: z.object({}).optional(),
  query: z.object({}).optional(),
});

const updateTripStatusSchema = z.object({
  params: z.object({ tripId: uuid }),
  body: z.object({
    status: z.enum(TRIP_STATUS_VALUES),
  }),
  query: z.object({}).optional(),
});

const createBookingSchema = z.object({
  body: z.object({
    tripId: uuid,
    pickupStopId: uuid,
    dropoffStopId: uuid,
    seatsBooked: z.number().int().min(1).max(10),
  }).refine((data) => data.pickupStopId !== data.dropoffStopId, {
    message: 'Pickup and dropoff stops must be different',
    path: ['dropoffStopId'],
  }),
  params: z.object({}).optional(),
  query: z.object({}).optional(),
});

const updateBookingStatusSchema = z.object({
  params: z.object({ bookingId: uuid }),
  body: z.object({
    status: z.enum(['pending', 'confirmed', 'cancelled', 'completed']),
  }),
  query: z.object({}).optional(),
});

const depositSchema = z.object({
  body: z.object({
    bookingId: uuid,
    amount: z.number().positive(),
    phoneNumber: z.string().min(7).max(20),
  }),
  params: z.object({}).optional(),
  query: z.object({}).optional(),
});

const updatePaymentStatusSchema = z.object({
  params: z.object({ paymentId: uuid }),
  body: z.object({
    status: z.enum(['pending', 'completed', 'failed']),
  }),
  query: z.object({}).optional(),
});

const createRatingSchema = z.object({
  body: z.object({
    tripId: uuid,
    rating: z.number().int().min(1).max(5),
    comment: z.string().max(500).optional().default(''),
  }),
  params: z.object({}).optional(),
  query: z.object({}).optional(),
});

const driverIdSchema = z.object({
  params: z.object({ driverId: uuid }),
  body: z.object({}).optional(),
  query: z.object({}).optional(),
});

const smartStopsSchema = z.object({
  query: z.object({ query: z.string().optional() }),
  body: z.object({}).optional(),
  params: z.object({}).optional(),
});

const smartPricingSchema = z.object({
  query: z.object({ routeId: uuid }),
  body: z.object({}).optional(),
  params: z.object({}).optional(),
});

module.exports = {
  authRegisterSchema,
  authLoginSchema,
  driverProfileSchema,
  vehicleSchema,
  verifyDriverSchema,
  createRouteSchema,
  addStopSchema,
  routeIdSchema,
  createTripSchema,
  searchTripsSchema,
  tripIdSchema,
  updateTripStatusSchema,
  createBookingSchema,
  updateBookingStatusSchema,
  depositSchema,
  updatePaymentStatusSchema,
  createRatingSchema,
  driverIdSchema,
  smartStopsSchema,
  smartPricingSchema,
};
