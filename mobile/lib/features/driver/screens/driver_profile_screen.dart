import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/driver_profile.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/driver_service.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseCtrl = TextEditingController();
  final _nidCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  DriverProfile? _profile;
  String? _error;

  @override
  void dispose() {
    _licenseCtrl.dispose();
    _nidCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile =
          await context.read<DriverService>().upsertProfile(
                licenseNumber: _licenseCtrl.text.trim(),
                nationalId: _nidCtrl.text.trim(),
                phone: _phoneCtrl.text.trim(),
              );
      if (!mounted) return;
      setState(() => _profile = profile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved. Awaiting verification.'),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_profile != null) ...[
                  Card(
                    color: _profile!.isApproved
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            _profile!.isApproved
                                ? Icons.verified
                                : Icons.hourglass_empty,
                            color: _profile!.isApproved
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Status: ${_profile!.verificationStatus}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _profile!.isApproved
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _licenseCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Licence Number',
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  validator: (v) =>
                      v != null && v.trim().length >= 4 ? null : 'Required',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nidCtrl,
                  decoration: const InputDecoration(
                    labelText: 'National ID',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) =>
                      v != null && v.trim().length >= 4 ? null : 'Required',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (v) =>
                      v != null && v.trim().length >= 7 ? null : 'Required',
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
                        child: const Text('Save Profile'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
