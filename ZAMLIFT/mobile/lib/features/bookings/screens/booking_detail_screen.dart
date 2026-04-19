import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/booking.dart';

class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final booking =
        ModalRoute.of(context)!.settings.arguments as Booking?;

    if (booking == null) {
      return const Scaffold(body: Center(child: Text('No booking data.')));
    }

    final fmt = DateFormat('EEEE, d MMMM yyyy • HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailRow('Route', booking.routeName ?? '–'),
          if (booking.departureTime != null)
            _DetailRow('Departure', fmt.format(booking.departureTime!.toLocal())),
          _DetailRow('Seats', '${booking.seatsBooked}'),
          _DetailRow('Total Price',
              'ZMW ${booking.totalPrice.toStringAsFixed(2)}'),
          _DetailRow('Status', booking.status),
          _DetailRow('Payment', booking.paymentStatus),
          const SizedBox(height: 24),
          if (!booking.isPaid)
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed(
                '/payments/deposit',
                arguments: booking,
              ),
              child: const Text('Pay Now'),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed('/chat', arguments: booking.tripId),
            icon: const Icon(Icons.chat_outlined),
            label: const Text('Open Trip Chat'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
