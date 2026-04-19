import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/auth_service.dart';
import 'core/services/booking_service.dart';
import 'core/services/chat_service.dart';
import 'core/services/driver_service.dart';
import 'core/services/payment_service.dart';
import 'core/services/rating_service.dart';
import 'core/services/route_service.dart';
import 'core/services/smart_service.dart';
import 'core/services/trip_service.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/bookings/providers/booking_provider.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/trips/providers/trip_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  final authService = AuthService(tokenStorage: tokenStorage);
  final driverService = DriverService(tokenStorage: tokenStorage);
  final routeService = RouteService(tokenStorage: tokenStorage);
  final tripService = TripService(tokenStorage: tokenStorage);
  final bookingService = BookingService(tokenStorage: tokenStorage);
  final paymentService = PaymentService(tokenStorage: tokenStorage);
  final ratingService = RatingService(tokenStorage: tokenStorage);
  final chatService = ChatService(tokenStorage: tokenStorage);
  final smartService = SmartService(tokenStorage: tokenStorage);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: authService),
        ),
        ChangeNotifierProvider(
          create: (_) => TripProvider(
            tripService: tripService,
            routeService: routeService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => BookingProvider(
            bookingService: bookingService,
            paymentService: paymentService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(chatService: chatService),
        ),
        // Expose individual services for screens that access them directly.
        Provider.value(value: driverService),
        Provider.value(value: routeService),
        Provider.value(value: paymentService),
        Provider.value(value: ratingService),
        Provider.value(value: smartService),
      ],
      child: const ZamLiftApp(),
    ),
  );
}
