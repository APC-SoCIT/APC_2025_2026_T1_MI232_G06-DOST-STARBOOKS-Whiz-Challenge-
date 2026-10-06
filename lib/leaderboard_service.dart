import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'leaderboard_constants.dart';
import 'config.dart';

/// All network calls for the Leaderboard screen.
/// Keeps the widget tree 100% free of raw HTTP logic.
class LeaderboardService {
  final http.Client _client;
  LeaderboardService(this._client);

  // ── Player profile ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchPlayerStars(String userId) async {
    try {
      final res = await _client.get(
        Uri.parse('${AppConfig.baseUrl}/players/$userId/stars'),
      );
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) return body['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Stars] $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchBadgeCounts(String userId) async {
    try {
      final res = await _client.get(
        Uri.parse('${AppConfig.baseUrl}/players/$userId/badges'),
      );
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) return body;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Badges] $e');
    }
    return null;
  }

  // ── Per-player game stats ───────────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchMemoryMatchStat(
      String userId, String difficulty) async {
    try {
      final res = await _client.get(Uri.parse(
        '${AppConfig.baseUrl}/game/fastest-time/$userId/memory_match/$difficulty',
      ));
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Memory] $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchPuzzleStat(
      String userId, String difficulty, String category) async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/game/fastest-time/$userId'
      '/puzzle/$difficulty?category=${Uri.encodeComponent(category)}',
    );
    try {
      if (kDebugMode) debugPrint('[Puzzle] $difficulty / $category');
      final res = await _client.get(uri);
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Puzzle] $e');
    }
    return null;
  }

  /// Scans ALL difficulty × category combos **in parallel** and returns the
  /// first combo that has a record for this player, or null if none found.
  Future<({int diffIdx, int catIdx, Map<String, dynamic> record})?> autoFindBestPuzzle(
      String userId) async {
    // Build one future per combo, keep index metadata alongside.
    final futures = <Future<({int di, int ci, Map<String, dynamic>? record})>>[];
    for (int di = 0; di < kGameDifficulties.length; di++) {
      for (int ci = 0; ci < kPuzzleCategories.length; ci++) {
        final diff = kGameDifficulties[di];
        final cat  = kPuzzleCategories[ci];
        final d = di, c = ci; // capture loop vars
        futures.add(
          fetchPuzzleStat(userId, diff, cat)
              .then((rec) => (di: d, ci: c, record: rec)),
        );
      }
    }

    final results = await Future.wait(futures);
    // Return the result with the lowest (di, ci) that has a record.
    results.sort((a, b) {
      final cmpD = a.di.compareTo(b.di);
      return cmpD != 0 ? cmpD : a.ci.compareTo(b.ci);
    });
    for (final r in results) {
      if (r.record != null) {
        return (diffIdx: r.di, catIdx: r.ci, record: r.record!);
      }
    }
    return null;
  }

  // ── Leaderboard tables ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchBadgesLeaderboard() async {
    // ✅ FIX: this used to call /leaderboard twice (?mode=challenge and
    // ?mode=battle) and add the two results together. That made sense
    // when the backend actually split totals by mode, but the endpoint
    // now returns one already-combined running total per player
    // (badges are tracked as flat totals in player_badges, not split by
    // game mode) — calling it twice and summing was silently doubling
    // every player's counts. A single call is now correct.
    try {
      final res = await _client.get(
        Uri.parse('${AppConfig.baseUrl}/leaderboard?limit=50'),
      );
      if (res.statusCode != 200) return [];

      final users = List<Map<String, dynamic>>.from(
          (json.decode(res.body)['users'] ?? []) as List);

      final sorted = users.toList()
        ..sort((a, b) {
          int total(Map m) =>
              (m['total_badges'] as int?) ??
              ((m['easy_count'] as int? ?? 0) +
                  (m['average_count'] as int? ?? 0) +
                  (m['difficult_count'] as int? ?? 0));
          return total(b).compareTo(total(a));
        });

      return sorted.take(20).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[BadgesLB] $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchStarsLeaderboard() async {
    try {
      final res = await _client.get(
        Uri.parse('${AppConfig.baseUrl}/stars/leaderboard?limit=20'),
      );
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return List<Map<String, dynamic>>.from((body['data'] ?? []) as List)
              .take(20)
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[StarsLB] $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchFastestTimeLeaderboard({
    required String gameType,
    required String difficulty,
    String? category,
  }) async {
    var url =
        '${AppConfig.baseUrl}/game/fastest-times/leaderboard'
        '?game_type=$gameType&difficulty=$difficulty&limit=50';
    if (category != null) url += '&category=${Uri.encodeComponent(category)}';

    try {
      final res = await _client.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return List<Map<String, dynamic>>.from((body['data'] ?? []) as List);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[FastestLB] $e');
    }
    return [];
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String _extractId(dynamic v) {
    if (v is Map) {
      if (v.containsKey('\$oid')) return v['\$oid'].toString();
      if (v.containsKey('oid'))   return v['oid'].toString();
    }
    return v?.toString() ?? '';
  }

  static String extractIdPublic(dynamic v) => _extractId(v);
}