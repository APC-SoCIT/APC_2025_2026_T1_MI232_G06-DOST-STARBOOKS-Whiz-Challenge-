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
      final response = await http.get(
        Uri.parse('$baseUrl/api/player-badge/${widget.playerId}/badges'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            badgeData = data['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to load badges';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
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
      final response = await http.post(
        Uri.parse('$baseUrl/api/player-badge/award'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'player_info_id': widget.playerId,
          'badge_username': 'Player',
          'participates_in': 'Achievement Claim',
          'difficulty': difficulty,
        }),
      );

      if (response.statusCode == 201) {
        await _fetchPlayerBadges();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${difficulty.toUpperCase()} badge claimed!'),
              backgroundColor: badgeColors[difficulty],
            ),
          );
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
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
                  const SizedBox(height: 20),
                  _buildSummary(),
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

    final summary = badgeData!['summary'];
    final badgeCount = summary['${difficulty}_badge_count'] ?? 0;
    final borderColor = badgeColors[difficulty] ?? Colors.grey;
    final badgeImage = badgeImages[difficulty] ?? "";

    final bool unlocked = badgeCount >= 3;
    final List<String?> badgePaths = List.generate(
      3,
          (i) => i < badgeCount ? badgeImage : null,
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
                color: borderColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$badgeCount/3',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: borderColor,
                ),
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

  Widget _buildSummary() {
    if (badgeData == null) return const SizedBox.shrink();

    final summary = badgeData!['summary'];
    final totalBadges = summary['total_badges'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Total Badges Collected',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalBadges',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF046EB8),
            ),
          ),
        ],
      ),
    );
  }
}