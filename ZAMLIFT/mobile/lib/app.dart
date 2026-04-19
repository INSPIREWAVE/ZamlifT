import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/bookings/screens/booking_detail_screen.dart';
import 'features/bookings/screens/bookings_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/driver/screens/driver_profile_screen.dart';
import 'features/driver/screens/vehicle_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/payments/screens/payment_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/ratings/screens/rating_screen.dart';
import 'features/smart/screens/smart_stops_screen.dart';
import 'features/trips/screens/trip_detail_screen.dart';
import 'features/trips/screens/trip_search_screen.dart';
import 'shared/theme/app_theme.dart';

class ZamLiftApp extends StatelessWidget {
  const ZamLiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZamLift',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const _RootGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const HomeScreen(),
        '/trips/search': (_) => const TripSearchScreen(),
        '/trips/detail': (_) => const TripDetailScreen(),
        '/bookings': (_) => const BookingsScreen(),
        '/bookings/detail': (_) => const BookingDetailScreen(),
        '/payments/deposit': (_) => const PaymentScreen(),
        '/driver/profile': (_) => const DriverProfileScreen(),
        '/driver/vehicle': (_) => const VehicleScreen(),
        '/chat': (_) => const ChatScreen(),
        '/ratings/new': (_) => const RatingScreen(),
        '/smart/stops': (_) => const SmartStopsScreen(),
      },
    );
  }
}

class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().tryRestoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.status == AuthStatus.authenticated) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
