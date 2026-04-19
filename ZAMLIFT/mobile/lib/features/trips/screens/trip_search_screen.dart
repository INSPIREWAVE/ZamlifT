import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/stop.dart';
import '../../../core/services/smart_service.dart';
import '../../trips/providers/trip_provider.dart';

class TripSearchScreen extends StatefulWidget {
  const TripSearchScreen({super.key});

  @override
  State<TripSearchScreen> createState() => _TripSearchScreenState();
}

class _TripSearchScreenState extends State<TripSearchScreen> {
  Stop? _fromStop;
  Stop? _toStop;
  DateTime _date = DateTime.now();
  List<Stop> _stopSuggestions = [];
  bool _loadingStops = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions([String query = '']) async {
    setState(() => _loadingStops = true);
    try {
      _stopSuggestions = await context
          .read<SmartService>()
          .getSuggestedStops(query: query);
    } finally {
      if (mounted) setState(() => _loadingStops = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _search() async {
    if (_fromStop == null || _toStop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both stops')),
      );
      return;
    }
    if (_fromStop!.id == _toStop!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick-up and drop-off must differ')),
      );
      return;
    }
    await context.read<TripProvider>().searchTrips(
          fromStopId: _fromStop!.id,
          toStopId: _toStop!.id,
          departureDate: _date,
        );
    if (!mounted) return;
    Navigator.of(context).pushNamed('/trips/detail');
  }

  Widget _stopSelector({
    required String label,
    required Stop? selected,
    required void Function(Stop) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final stop = await _showStopPicker();
            if (stop != null) onSelect(stop);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'Select a stop',
              suffixIcon: const Icon(Icons.arrow_drop_down),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor:
                  Theme.of(context).inputDecorationTheme.fillColor,
            ),
            child: Text(selected?.displayName ?? 'Select a stop'),
          ),
        ),
      ],
    );
  }

  Future<Stop?> _showStopPicker() {
    return showModalBottomSheet<Stop>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, sc) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search stops...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _loadSuggestions,
              ),
            ),
            Expanded(
              child: _loadingStops
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: sc,
                      itemCount: _stopSuggestions.length,
                      itemBuilder: (_, i) {
                        final s = _stopSuggestions[i];
                        return ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text(s.name),
                          subtitle: Text(s.city),
                          onTap: () => Navigator.of(ctx).pop(s),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Find a Trip')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _stopSelector(
                label: 'From',
                selected: _fromStop,
                onSelect: (s) => setState(() => _fromStop = s),
              ),
              const SizedBox(height: 16),
              _stopSelector(
                label: 'To',
                selected: _toStop,
                onSelect: (s) => setState(() => _toStop = s),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text('Date: ${DateFormat('EEE, d MMM yyyy').format(_date)}'),
                trailing: const Icon(Icons.edit),
                onTap: _pickDate,
              ),
              const SizedBox(height: 24),
              provider.loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _search,
                      icon: const Icon(Icons.search),
                      label: const Text('Search Trips'),
                    ),
              if (provider.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  provider.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
