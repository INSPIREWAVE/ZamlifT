import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _loading = false;
  String? _message;

  Future<void> _book(int tripId) async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      await context.read<ApiService>().createBooking(
            tripId: tripId,
            seatsBooked: 1,
            pickupStopId: 1,
            dropoffStopId: 2,
          );
      setState(() => _message = 'Booking created. Complete payment to confirm.');
    } catch (error) {
      setState(() => _message = 'Booking failed: $error');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map<String, dynamic>;
    final tripId = trip['id'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Book Trip')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${trip['start_location']} → ${trip['destination']}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Price: UGX ${trip['price']}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading || tripId == 0 ? null : () => _book(tripId),
              child: const Text('Book 1 Seat'),
            ),
            if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!)),
          ],
        ),
      ),
    );
  }
}
