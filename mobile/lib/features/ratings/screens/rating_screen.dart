import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/rating_service.dart';

/// Rating submission screen.
///
/// Route argument: `tripId` (String).
///
/// Calls POST /api/ratings with:
///   { "tripId": "...", "rating": 1-5, "comment": "..." }
///
/// Constraints enforced by the backend:
///   - Trip must be completed.
///   - Caller must have a completed booking on that trip.
class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _stars = 5;
  final _commentCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(String tripId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<RatingService>().createRating(
            tripId: tripId,
            rating: _stars,
            comment: _commentCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your rating!'),
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
    final tripId = ModalRoute.of(context)!.settings.arguments as String?;

    if (tripId == null) {
      return const Scaffold(body: Center(child: Text('No trip selected.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rate Your Driver')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'How was your trip?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => IconButton(
                    icon: Icon(
                      i < _stars ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                    onPressed: () => setState(() => _stars = i + 1),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _commentCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
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
                  : ElevatedButton.icon(
                      onPressed: () => _submit(tripId),
                      icon: const Icon(Icons.star),
                      label: const Text('Submit Rating'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  String get _label => switch (_stars) {
        1 => 'Poor',
        2 => 'Fair',
        3 => 'Good',
        4 => 'Very Good',
        _ => 'Excellent',
      };
}
