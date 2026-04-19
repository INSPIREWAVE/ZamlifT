import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/booking.dart';
import '../../bookings/providers/booking_provider.dart';
import '../../../shared/widgets/error_view.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<BookingProvider>().loadMyBookings(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? ErrorView(
                  message: provider.error!,
                  onRetry: () =>
                      context.read<BookingProvider>().loadMyBookings(),
                )
              : provider.bookings.isEmpty
                  ? const Center(
                      child: Text('No bookings yet. Find a trip to get started!'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: provider.bookings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) =>
                          _BookingCard(booking: provider.bookings[i]),
                    ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE d MMM • HH:mm');

    return Card(
      child: ListTile(
        title: Text(
          booking.routeName ?? 'Trip #${booking.tripId.substring(0, 8)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (booking.departureTime != null)
              Text(fmt.format(booking.departureTime!.toLocal())),
            Text(
              '${booking.seatsBooked} seat(s) • ZMW ${booking.totalPrice.toStringAsFixed(2)}',
            ),
            Row(
              children: [
                _StatusBadge(booking.status),
                const SizedBox(width: 8),
                _StatusBadge(booking.paymentStatus, isPayment: true),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleAction(context, action),
          itemBuilder: (_) => [
            if (!booking.isCancelled)
              const PopupMenuItem(
                value: 'cancel',
                child: Text('Cancel'),
              ),
            if (!booking.isPaid)
              const PopupMenuItem(
                value: 'pay',
                child: Text('Pay Now'),
              ),
            const PopupMenuItem(
              value: 'chat',
              child: Text('Open Chat'),
            ),
            const PopupMenuItem(
              value: 'rate',
              child: Text('Rate Driver'),
            ),
          ],
        ),
        onTap: () => Navigator.of(context).pushNamed(
          '/bookings/detail',
          arguments: booking,
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'cancel':
        context.read<BookingProvider>().cancelBooking(booking.id);
      case 'pay':
        Navigator.of(context).pushNamed('/payments/deposit', arguments: booking);
      case 'chat':
        Navigator.of(context).pushNamed('/chat', arguments: booking.tripId);
      case 'rate':
        Navigator.of(context).pushNamed('/ratings/new', arguments: booking.tripId);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status, {this.isPayment = false});
  final String status;
  final bool isPayment;

  Color get _color => switch (status) {
        'pending' => Colors.orange,
        'confirmed' || 'paid' || 'completed' => Colors.green,
        'cancelled' || 'failed' => Colors.red,
        _ => Colors.blueGrey,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, color: _color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
