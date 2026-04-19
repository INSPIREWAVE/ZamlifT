import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/stop.dart';
import '../../../core/services/smart_service.dart';

/// Smart stop autocomplete screen.
///
/// Calls GET /api/smart/stops?query=<text>
class SmartStopsScreen extends StatefulWidget {
  const SmartStopsScreen({super.key});

  @override
  State<SmartStopsScreen> createState() => _SmartStopsScreenState();
}

class _SmartStopsScreenState extends State<SmartStopsScreen> {
  final _ctrl = TextEditingController();
  List<Stop> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    try {
      final stops =
          await context.read<SmartService>().getSuggestedStops(query: q);
      if (mounted) setState(() => _results = stops);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Popular Stops')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                hintText: 'Search stops or cities...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(child: Text('No stops found.'))
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final s = _results[i];
                          return ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(s.name),
                            subtitle: Text(s.city),
                            trailing: s.popularityScore > 0
                                ? Chip(
                                    label: Text('★ ${s.popularityScore}'),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  )
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
