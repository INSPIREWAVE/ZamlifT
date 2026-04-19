import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/booking.dart';
import '../../bookings/providers/booking_provider.dart';

/// Mobile-money payment screen.
///
/// Route argument: [Booking] (passed from bookings list or trip detail).
///
/// Calls POST /api/payments/deposit with:
///   { "bookingId": "...", "amount": ..., "phoneNumber": "..." }
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(Booking booking) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final payment = await context.read<BookingProvider>().deposit(
          bookingId: booking.id,
          amount: booking.totalPrice,
          phoneNumber: _phoneCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (payment != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment initiated! Reference: ${payment.reference}',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<BookingProvider>().error ?? 'Payment failed',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking =
        ModalRoute.of(context)!.settings.arguments as Booking?;

    if (booking == null) {
      return const Scaffold(body: Center(child: Text('No booking selected.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mobile Money Payment')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          booking.routeName ?? 'Trip',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${booking.seatsBooked} seat(s)',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ZMW ${booking.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B6CA8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Money Number',
                    hintText: '+260977000000',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (v) => v != null && v.trim().length >= 7
                      ? null
                      : 'Enter a valid phone number',
                ),
                const SizedBox(height: 24),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: () => _submit(booking),
                        icon: const Icon(Icons.payment),
                        label: const Text('Pay Now'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
