import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

/// Polls the server for "the admin just gave you your prize" and shows a
/// message when it happens.
///
/// Usage (any player-side screen that should react, e.g. the home page):
///
///   late final PrizeNotifier _prizeNotifier;
///
///   initState:
///     _prizeNotifier = PrizeNotifier(playerId: widget.userId)..start(context);
///
///   dispose:
///     _prizeNotifier.stop();
///
/// Several notifiers can be active at once; a shared flag makes sure only one
/// message is on screen, and the server marks each prize as notified so it is
/// never shown twice.
class PrizeNotifier {
  PrizeNotifier({
    required this.playerId,
    String? baseUrl,
    this.interval = const Duration(seconds: 8),
    this.onAwarded,
  }) : baseUrl = baseUrl ?? AppConfig.baseUrl;

  final String playerId;
  final String baseUrl;
  final Duration interval;

  /// Called after the message is dismissed, e.g. to refresh badge data.
  final VoidCallback? onAwarded;

  Timer? _timer;
  BuildContext? _context;
  static bool _busy = false; // shared across notifiers

  void start(BuildContext context) {
    _context = context;
    _timer?.cancel();
    _check(); // check immediately, then keep polling
    _timer = Timer.periodic(interval, (_) => _check());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _context = null;
  }

  Future<void> _check() async {
    final ctx = _context;
    if (_busy || ctx == null || !ctx.mounted) return;
    _busy = true;
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/badges/player/$playerId/prize-notifications'),
              headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;

      final body = json.decode(res.body);
      if (body['success'] != true) return;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      if (data['has_new'] != true) return;

      final counts = Map<String, dynamic>.from(data['counts'] ?? {});

      // Mark as seen first so a second poller can't show it again.
      await http
          .post(Uri.parse('$baseUrl/badges/player/$playerId/prize-notifications/ack'),
              headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));

      if (!ctx.mounted) return;
      await _showMessage(ctx, counts);
      onAwarded?.call();
    } catch (_) {
      // Network hiccup: try again on the next tick.
    } finally {
      _busy = false;
    }
  }

  Future<void> _showMessage(BuildContext ctx, Map<String, dynamic> counts) {
    const labels = {'easy': 'Easy', 'average': 'Average', 'difficult': 'Difficult'};
    const colors = {
      'easy': Color(0xFF1D9358),
      'average': Color(0xFF046EB8),
      'difficult': Color(0xFFBD442E),
    };

    final lines = <Widget>[];
    for (final key in ['easy', 'average', 'difficult']) {
      final n = (counts[key] as num?)?.toInt() ?? 0;
      if (n <= 0) continue;
      lines.add(Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          n == 1 ? '${labels[key]} prize' : '${labels[key]} prize x$n',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            color: colors[key],
          ),
        ),
      ));
    }

    return showDialog<void>(
      context: ctx,
      useRootNavigator: true,
      builder: (dctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 56, color: Color(0xFFF7C600)),
              const SizedBox(height: 12),
              const Text(
                'Prize Claimed!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 8),
              Text(
                'The admin has given your prize. Enjoy your reward!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontFamily: 'Poppins', color: Colors.grey.shade600),
              ),
              ...lines,
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046EB8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 0,
                  ),
                  child: const Text('Yay!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
