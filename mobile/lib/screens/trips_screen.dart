import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  late Future<List<dynamic>> _trips;

  @override
  void initState() {
    super.initState();
    _trips = context.read<ApiService>().searchTrips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Trips')),
      body: FutureBuilder<List<dynamic>>(
        future: _trips,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final trips = snapshot.data ?? [];
          if (trips.isEmpty) {
            return const Center(child: Text('No trips available'));
          }
          return ListView.builder(
            itemCount: trips.length,
            itemBuilder: (_, index) {
              final trip = trips[index] as Map<String, dynamic>;
              return ListTile(
                title: Text('${trip['start_location']} → ${trip['destination']}'),
                subtitle: Text('UGX ${trip['price']} | Seats: ${trip['available_seats']}'),
                onTap: () => Navigator.pushNamed(context, '/booking', arguments: trip),
              );
            },
          );
        },
      ),
    );
  }
}
