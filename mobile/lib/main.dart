import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/booking_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';
import 'screens/trips_screen.dart';
import 'services/api_service.dart';
import 'services/socket_service.dart';

void main() {
  runApp(const ZamLiftMobileApp());
}

class ZamLiftMobileApp extends StatelessWidget {
  const ZamLiftMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
        Provider(create: (_) => SocketService()),
      ],
      child: MaterialApp(
        title: 'ZamLift',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
        initialRoute: '/login',
        routes: {
          '/login': (_) => const LoginScreen(),
          '/trips': (_) => const TripsScreen(),
          '/booking': (_) => const BookingScreen(),
          '/chat': (_) => const ChatScreen(),
        },
      ),
    );
  }
}
