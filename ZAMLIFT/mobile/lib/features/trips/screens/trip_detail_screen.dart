import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/trip.dart';
import '../../bookings/providers/booking_provider.dart';
import '../../trips/providers/trip_provider.dart';

/// Displays search results AND allows drilling into a single trip.
class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final results = context.select((TripProvider p) => p.searchResults);

    return Scaffold(
      appBar: AppBar(title: const Text('Available Trips')),
      body: results.isEmpty
          ? const Center(child: Text('No trips found for your search.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _TripCard(trip: results[i]),
            ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE d MMM • HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trip.routeName ?? '${trip.originCity} → ${trip.destinationCity}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                _StatusChip(status: trip.status),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(Icons.schedule, fmt.format(trip.departureTime.toLocal())),
            _InfoRow(Icons.person_outline, 'Driver: ${trip.driverName ?? "–"}'),
            _InfoRow(Icons.event_seat,
                '${trip.seatsAvailable} seat${trip.seatsAvailable == 1 ? "" : "s"} left'),
            _InfoRow(Icons.payments_outlined,
                'ZMW ${trip.pricePerSeat.toStringAsFixed(2)} / seat'),
            const SizedBox(height: 12),
            if (trip.isBookable)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showBookingDialog(context, trip),
                  child: const Text('Book Now'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBookingDialog(BuildContext context, Trip trip) {
    int seats = 1;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Confirm Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Route: ${trip.routeName ?? "–"}'),
              Text('Price/seat: ZMW ${trip.pricePerSeat.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (seats > 1) setState(() => seats--);
                    },
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$seats', style: const TextStyle(fontSize: 18)),
                  IconButton(
                    onPressed: () {
                      if (seats < trip.seatsAvailable && seats < 10) {
                        setState(() => seats++);
                      }
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              Text(
                'Total: ZMW ${(trip.pricePerSeat * seats).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                // Pickup/dropoff stops default to route endpoints; in a full
                // implementation a stop-picker would appear here. We pass the
                // trip's route_id — the user should select stops in a
                // dedicated flow. For now we surface the payment screen.
                final booking =
                    await context.read<BookingProvider>().createBooking(
                          tripId: trip.id,
                          pickupStopId: trip.routeId, // placeholder
                          dropoffStopId: trip.routeId, // placeholder
                          seatsBooked: seats,
                        );
                if (!context.mounted) return;
                if (booking != null) {
                  Navigator.of(context).pushNamed(
                    '/payments/deposit',
                    arguments: booking,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.read<BookingProvider>().error ??
                            'Booking failed',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  Color get _color => switch (status) {
        'scheduled' => Colors.blue,
        'ongoing' => Colors.green,
        'completed' => Colors.grey,
        'cancelled' => Colors.red,
        _ => Colors.blueGrey,
      };

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
      backgroundColor: _color,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
