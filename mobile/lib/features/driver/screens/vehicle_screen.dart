import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/driver_service.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _plateCtrl.dispose();
    _seatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final vehicle = await context.read<DriverService>().registerVehicle(
            make: _makeCtrl.text.trim(),
            model: _modelCtrl.text.trim(),
            year: int.parse(_yearCtrl.text.trim()),
            plateNumber: _plateCtrl.text.trim(),
            seatCapacity: int.parse(_seatsCtrl.text.trim()),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vehicle ${vehicle.plateNumber} registered!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    return Scaffold(
      appBar: AppBar(title: const Text('Register Vehicle')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _makeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Make (e.g. Toyota)',
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  validator: (v) =>
                      v != null && v.trim().length >= 2 ? null : 'Required',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modelCtrl,
                  decoration: const InputDecoration(labelText: 'Model'),
                  validator: (v) =>
                      v != null && v.trim().isNotEmpty ? null : 'Required',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _yearCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Year'),
                  validator: (v) {
                    final y = int.tryParse(v ?? '');
                    if (y == null || y < 1980 || y > currentYear + 2) {
                      return 'Enter a year between 1980 and ${currentYear + 2}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _plateCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Plate Number'),
                  validator: (v) =>
                      v != null && v.trim().length >= 3 ? null : 'Required',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _seatsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Seat Capacity'),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 1 || n > 100) {
                      return 'Enter 1–100 seats';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Register Vehicle'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
