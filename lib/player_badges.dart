import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlayerBadgesDialog extends StatefulWidget {
  final String playerId;

  const PlayerBadgesDialog({
    super.key,
    required this.playerId,
  });

  @override
  State<PlayerBadgesDialog> createState() => _PlayerBadgesDialogState();
}

class _PlayerBadgesDialogState extends State<PlayerBadgesDialog> {
  bool isLoading = true;
  Map<String, dynamic>? badgeData;
  List<dynamic> unclaimedBadges = [];
  String? errorMessage;
  final String baseUrl = "http://127.0.0.1:8000";

  // Badge categories with their image mappings
  final Map<String, String> badgeImages = {
    "easy": "assets/images-badges/whiz-ready.png",
    "average": "assets/images-badges/whiz-happy.png",
    "difficult": "assets/images-badges/whiz-achiever.png",
  };

  final Map<String, Color> badgeColors = {
    "easy": const Color(0xFF1D9358),
    "average": const Color(0xFF046EB8),
    "difficult": const Color(0xFFBD442E),
  };

  @override
  void initState() {
    super.initState();
    _fetchPlayerBadges();
  }

  Future<void> _fetchPlayerBadges() async {
    try {
      // Fetch badge summary
      final summaryResponse = await http.get(
        Uri.parse('$baseUrl/api/badges/player/${widget.playerId}/summary'),
      );

      // Fetch unclaimed official badges
      final unclaimedResponse = await http.get(
        Uri.parse(
            '$baseUrl/api/badges/official/player/${widget.playerId}/unclaimed'),
      );

      if (summaryResponse.statusCode == 200 &&
          unclaimedResponse.statusCode == 200) {
        final summaryData = json.decode(summaryResponse.body);
        final unclaimedData = json.decode(unclaimedResponse.body);

        if (summaryData['success'] && unclaimedData['success']) {
          setState(() {
            badgeData = summaryData['data'];
            unclaimedBadges = unclaimedData['data']['badges'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage =
            'Failed to load badges: ${summaryData['message'] ?? unclaimedData['message']}';
            isLoading = false;
          });
        }
      } else {
        final errorBody = summaryResponse.statusCode != 200
            ? summaryResponse.body
            : unclaimedResponse.body;
        setState(() {
          errorMessage =
          'Server error ${summaryResponse.statusCode}: $errorBody';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading badges: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _claimBadge(String difficulty) async {
    try {
      // Find the unclaimed badge for this difficulty
      final badgeToClaim = unclaimedBadges.firstWhere(
            (badge) =>
        badge['difficulty'] == difficulty && badge['claimed'] == false,
        orElse: () => null,
      );

      if (badgeToClaim == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No badge available to claim'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Claim the specific badge
      final response = await http.post(
        Uri.parse(
            '$baseUrl/api/badges/official/${badgeToClaim['_id']}/claim'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // Refresh the badge data
          await _fetchPlayerBadges();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '🎉 ${difficulty.toUpperCase()} Official Badge Claimed!'),
                backgroundColor: badgeColors[difficulty],
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error claiming badge: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Check if there's an unclaimed badge for a specific difficulty
  bool _hasUnclaimedBadge(String difficulty) {
    return unclaimedBadges.any((badge) =>
    badge['difficulty'] == difficulty && badge['claimed'] == false);
  }

  // Get the number of official badges for a difficulty
  int _getOfficialBadgeCount(String difficulty) {
    if (badgeData == null) return 0;
    final officialBadges = badgeData!['official_badges'];
    return officialBadges[difficulty] ?? 0;
  }

  // Get progress towards next badge
  Map<String, int> _getProgress(String difficulty) {
    if (badgeData == null) {
      return {'current': 0, 'needed': 3, 'remaining': 3};
    }

    final progress = badgeData!['progress'][difficulty];
    return {
      'current': progress['current_count'] ?? 0,
      'needed': 3,
      'remaining': progress['badges_remaining'] ?? 3,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 410, maxHeight: 750),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                          errorMessage = null;
                        });
                        _fetchPlayerBadges();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
                : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBadgeCategory("Easy", "easy"),
                  const SizedBox(height: 20),
                  _buildBadgeCategory("Average", "average"),
                  const SizedBox(height: 20),
                  _buildBadgeCategory("Difficult", "difficult"),
                ],
              ),
            ),
          ),
          Positioned(
            top: -74,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                "assets/images-badges/whiz-achiever.png",
                width: 220,
                height: 145,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCategory(String title, String difficulty) {
    if (badgeData == null) return const SizedBox.shrink();

    final officialCount = _getOfficialBadgeCount(difficulty);
    final progress = _getProgress(difficulty);
    final hasUnclaimed = _hasUnclaimedBadge(difficulty);

    final borderColor = badgeColors[difficulty] ?? Colors.grey;
    final badgeImage = badgeImages[difficulty] ?? "";

    // Calculate badges remaining to next milestone
    final remaining = progress['remaining']!;

    // Show count based on how many more needed (3 - remaining)
    final currentInSet = 3 - remaining;
    final showCount = currentInSet;

    // Show unlocked if we have an unclaimed badge (meaning we hit 3)
    final unlocked = hasUnclaimed;

    final List<String?> badgePaths = List.generate(
      3,
          (i) => i < showCount ? badgeImage : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: borderColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${3 - remaining}/3',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: borderColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (officialCount > 0)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha:0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '$officialCount Official',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ...List.generate(3, (i) {
              final path = badgePaths[i];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: path != null ? borderColor : Colors.grey.shade300,
                      width: 3,
                    ),
                    color: path == null ? Colors.grey.shade100 : null,
                  ),
                  child: path != null
                      ? ClipOval(
                    child: Image.asset(path, fit: BoxFit.contain),
                  )
                      : Center(
                    child: Icon(
                      Icons.lock_outline,
                      color: Colors.grey.shade400,
                      size: 30,
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            ElevatedButton(
              onPressed: unlocked ? () => _claimBadge(difficulty) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                unlocked ? borderColor : Colors.grey.shade300,
                foregroundColor:
                unlocked ? Colors.white : Colors.grey.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 25, vertical: 17),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text(unlocked ? "CLAIM!" : "LOCKED"),
            ),
          ],
        ),
      ],
    );
  }
}