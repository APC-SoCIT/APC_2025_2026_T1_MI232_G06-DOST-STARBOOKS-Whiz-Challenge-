import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class Leaderboard extends StatefulWidget {
  final String? currentUserId; // Add this to pass user ID

  const Leaderboard({super.key, this.currentUserId});

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  final String baseUrl = "http://127.0.0.1:8000";
  String selectedMode = "challenge";
  List<Map<String, dynamic>> leaderboardData = [];
  bool isLoading = true;
  int? currentUserRank;
  Map<String, dynamic>? currentUserData;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = widget.currentUserId; // Initialize from widget
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => isLoading = true);

    try {
      // TODO: Get current user ID from your auth/session management
      // For now, you can pass it through the widget or use a global state
      // currentUserId = getCurrentUserId();

      final url = "$baseUrl/api/leaderboard?mode=$selectedMode";
      if (kDebugMode) {
        debugPrint('Fetching leaderboard from: $url');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout - check if backend is running');
        },
      );

      if (kDebugMode) {
        debugPrint('Response status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          debugPrint('Decoded data: $data');
        }

        if (data['success'] == true) {
          final List<dynamic> users = data['users'] ?? [];

          setState(() {
            leaderboardData = List<Map<String, dynamic>>.from(users);

            // Find current user's position if userId is available
            if (currentUserId != null) {
              final userIndex = leaderboardData.indexWhere(
                      (user) => user['id']?.toString() == currentUserId ||
                      user['_id']?['\$oid']?.toString() == currentUserId
              );
              if (userIndex != -1) {
                currentUserRank = userIndex + 1;
                currentUserData = leaderboardData[userIndex];
              }
            }

            isLoading = false;
          });
        } else {
          if (kDebugMode) {
            debugPrint('API returned success: false');
          }
          setState(() => isLoading = false);
          _showErrorDialog('Failed to load leaderboard data');
        }
      } else {
        if (kDebugMode) {
          debugPrint('HTTP Error: ${response.statusCode}');
        }
        setState(() => isLoading = false);
        _showErrorDialog('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading leaderboard: $e');
      }
      setState(() => isLoading = false);
      _showErrorDialog('Connection failed: $e');
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadLeaderboard();
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _extractId(dynamic idValue) {
    if (idValue is Map && idValue.containsKey('\$oid')) {
      return idValue['\$oid'].toString();
    }
    return idValue?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (currentUserData != null) _buildUserStatsCard(),
              Expanded(child: _buildLeaderboardList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Racing Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.emoji_events, color: Colors.amber, size: 32),
              SizedBox(width: 12),
              Text(
                "LEADERBOARD",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            ],
          ),
          const SizedBox(height: 20),

          // Mode Toggle Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildModeButton("🏁 Whiz Challenge", "challenge"),
              const SizedBox(width: 12),
              _buildModeButton("⚔️ Whiz Battle", "battle"),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIconButton(Icons.refresh, "Refresh", _loadLeaderboard),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatsCard() {
    if (currentUserData == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE94560).withValues(alpha: 0.8),
            const Color(0xFFFF6B9D).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE94560).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber, width: 3),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "#${currentUserRank}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE94560),
                    ),
                  ),
                  Text(
                    "RANK",
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "YOUR POSITION",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUserData!['username'] ?? 'You',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Stats
          Column(
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 24),
              const SizedBox(height: 4),
              Text(
                "${currentUserData!['total_rewards'] ?? currentUserData!['rewards'] ?? 0}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                "REWARDS",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE94560),
        ),
      );
    }

    if (leaderboardData.isEmpty) {
      return const Center(
        child: Text(
          "No data available",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        itemCount: leaderboardData.length,
        itemBuilder: (context, index) {
          final player = leaderboardData[index];
          final rank = index + 1;
          final playerId = _extractId(player['id'] ?? player['_id']);
          final isCurrentUser = currentUserId != null && playerId == currentUserId;

          return _buildRacerCard(player, rank, isCurrentUser);
        },
      ),
    );
  }

  Widget _buildRacerCard(Map<String, dynamic> player, int rank, bool isCurrentUser) {
    Color cardColor = isCurrentUser
        ? const Color(0xFFE94560).withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.05);

    Color borderColor = isCurrentUser
        ? const Color(0xFFE94560)
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: isCurrentUser
            ? [
          BoxShadow(
            color: const Color(0xFFE94560).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ]
            : null,
      ),
      child: Row(
        children: [
          // Rank Badge
          _buildRacingRankBadge(rank),
          const SizedBox(width: 16),

          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getRankColor(rank),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                player['avatar'] ?? "assets/images-avatars/Adventurer.png",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.person, color: Colors.white);
                },
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Username
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player['username'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (isCurrentUser)
                  const Text(
                    "YOU",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE94560),
                    ),
                  ),
              ],
            ),
          ),

          // Stats in compact racing style
          _buildStatBadge(
            "${player['total_rewards'] ?? player['rewards'] ?? 0}",
            Icons.stars,
            Colors.amber,
          ),
          const SizedBox(width: 8),
          _buildStatBadge(
            "${player['easy_count'] ?? player['easy'] ?? 0}",
            Icons.circle,
            const Color(0xFF1D9358),
          ),
          const SizedBox(width: 8),
          _buildStatBadge(
            "${player['average_count'] ?? player['avg'] ?? 0}",
            Icons.circle,
            const Color(0xFF046EB8),
          ),
          const SizedBox(width: 8),
          _buildStatBadge(
            "${player['difficult_count'] ?? player['diff'] ?? 0}",
            Icons.circle,
            const Color(0xFFBD442E),
          ),
        ],
      ),
    );
  }

  Widget _buildRacingRankBadge(int rank) {
    Color bgColor = _getRankColor(rank);
    IconData? medalIcon;

    if (rank <= 3) {
      medalIcon = Icons.emoji_events;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: medalIcon != null
            ? Icon(medalIcon, color: Colors.white, size: 28)
            : Text(
          "$rank",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return const Color(0xFF4A5568); // Gray
    }
  }

  Widget _buildStatBadge(String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, String mode) {
    final bool isSelected = selectedMode == mode;
    return ElevatedButton(
      onPressed: () {
        setState(() => selectedMode = mode);
        _loadLeaderboard();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? const Color(0xFFE94560)
            : Colors.white.withValues(alpha: 0.1),
        foregroundColor: Colors.white,
        elevation: isSelected ? 8 : 0,
        shadowColor: const Color(0xFFE94560).withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFFE94560)
                : Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}