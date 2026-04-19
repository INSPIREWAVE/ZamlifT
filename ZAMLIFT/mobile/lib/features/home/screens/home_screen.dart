import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthProvider p) => p.user);
    final isDriver = user?.isDriver ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZamLift'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Welcome, ${user?.fullName ?? 'Guest'}!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            _NavCard(
              icon: Icons.search,
              title: 'Find a Trip',
              subtitle: 'Search available trips between stops',
              onTap: () => Navigator.of(context).pushNamed('/trips/search'),
            ),
            _NavCard(
              icon: Icons.book_online,
              title: 'My Bookings',
              subtitle: 'View and manage your bookings',
              onTap: () => Navigator.of(context).pushNamed('/bookings'),
            ),
            if (isDriver) ...[
              _NavCard(
                icon: Icons.badge,
                title: 'Driver Profile',
                subtitle: 'Manage your driver profile',
                onTap: () =>
                    Navigator.of(context).pushNamed('/driver/profile'),
              ),
              _NavCard(
                icon: Icons.directions_car,
                title: 'My Vehicle',
                subtitle: 'Register or update your vehicle',
                onTap: () =>
                    Navigator.of(context).pushNamed('/driver/vehicle'),
              ),
            ],
            _NavCard(
              icon: Icons.location_on_outlined,
              title: 'Smart Stops',
              subtitle: 'Find popular stops along routes',
              onTap: () => Navigator.of(context).pushNamed('/smart/stops'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32, color: const Color(0xFF1B6CA8)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
