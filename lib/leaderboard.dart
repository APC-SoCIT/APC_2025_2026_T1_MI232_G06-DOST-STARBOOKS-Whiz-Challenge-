import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class Leaderboard extends StatefulWidget {
  final String currentUserId;
  final String userAvatar;
  final String username;

  const Leaderboard({
    super.key,
    required this.currentUserId,
    required this.userAvatar,
    required this.username,
  });

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  final String baseUrl = "http://127.0.0.1:8000";

  String selectedGame = "whiz_challenge";
  String selectedDifficulty = "EASY"; // For fastest time games
  String selectedCategory = "Solar System"; // For puzzle game
  String selectedQuizCategory = "Math"; // For quiz games (Challenge/Battle)
  bool isLoading = true;

  // User stats for badges section
  Map<String, dynamic>? currentUserStats;

  // Leaderboard data
  List<Map<String, dynamic>> leaderboardData = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => isLoading = true);

    try {
      if (selectedGame == "whiz_challenge" || selectedGame == "whiz_battle") {
        await _loadQuizLeaderboard();
      } else if (selectedGame == "whiz_memory_match" || selectedGame == "whiz_puzzle") {
        await _loadFastestTimeLeaderboard();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading leaderboard: $e');
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadQuizLeaderboard() async {
    final mode = selectedGame == "whiz_challenge" ? "challenge" : "battle";

    // Build URL with filters
    String url = "$baseUrl/api/leaderboard?mode=$mode";

    // Add difficulty filter
    url += "&difficulty=$selectedDifficulty";

    // Add category filter (Math/Science)
    url += "&category=$selectedQuizCategory";

    try {
      if (kDebugMode) {
        debugPrint('Quiz leaderboard URL: $url');
      }

      final response = await http.get(Uri.parse(url));

      if (kDebugMode) {
        debugPrint('Quiz leaderboard response: ${response.statusCode}');
        debugPrint('Quiz leaderboard body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> users = data['users'] ?? [];

          setState(() {
            leaderboardData = List<Map<String, dynamic>>.from(users);

            // Find current user stats
            final userIndex = leaderboardData.indexWhere(
                    (user) => _extractId(user['id'] ?? user['_id']) == widget.currentUserId
            );

            if (userIndex != -1) {
              currentUserStats = leaderboardData[userIndex];
            } else {
              currentUserStats = null;
            }
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in _loadQuizLeaderboard: $e');
      }
    }
  }

  Future<void> _loadFastestTimeLeaderboard() async {
    final gameType = selectedGame == "whiz_memory_match" ? "memory_match" : "puzzle";

    String url = "$baseUrl/api/game/fastest-times/leaderboard?game_type=$gameType&difficulty=$selectedDifficulty&limit=50";

    // Add category for puzzle games
    if (gameType == "puzzle") {
      url += "&category=${Uri.encodeComponent(selectedCategory)}";
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (kDebugMode) {
        debugPrint('Fastest time API URL: $url');
        debugPrint('Response status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> records = data['data'] ?? [];

          setState(() {
            leaderboardData = List<Map<String, dynamic>>.from(records);

            // Find current user
            final userIndex = leaderboardData.indexWhere(
                    (record) => _extractId(record['player_id']) == widget.currentUserId
            );

            if (userIndex != -1) {
              currentUserStats = leaderboardData[userIndex];
            } else {
              currentUserStats = null;
            }
          });
        }
      } else {
        if (kDebugMode) {
          debugPrint('API returned error: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in _loadFastestTimeLeaderboard: $e');
      }
    }
  }

  String _extractId(dynamic idValue) {
    if (idValue is Map) {
      if (idValue.containsKey('\$oid')) {
        return idValue['\$oid'].toString();
      } else if (idValue.containsKey('oid')) {
        return idValue['oid'].toString();
      }
    }
    return idValue?.toString() ?? '';
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  Widget _buildFilterTabs() {
    if (selectedGame == "whiz_challenge" || selectedGame == "whiz_battle") {
      // Category tabs for quiz games
      return _buildCategoryTabs();
    } else if (selectedGame == "whiz_memory_match") {
      // Difficulty tabs for memory match
      return _buildDifficultyTabs();
    } else if (selectedGame == "whiz_puzzle") {
      // Both difficulty and category tabs for puzzle
      return Column(
        children: [
          _buildDifficultyTabs(),
          const SizedBox(height: 12),
          _buildPuzzleCategoryTabs(),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCategoryTabs() {
    final categories = ["Math", "Science"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedQuizCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildTabButton(
              label: category,
              isSelected: isSelected,
              onTap: () {
                setState(() => selectedQuizCategory = category);
                _loadLeaderboard();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDifficultyTabs() {
    final difficulties = ["EASY", "AVERAGE", "DIFFICULT"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: difficulties.map((difficulty) {
          final isSelected = selectedDifficulty == difficulty;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildTabButton(
              label: difficulty,
              isSelected: isSelected,
              onTap: () {
                setState(() => selectedDifficulty = difficulty);
                _loadLeaderboard();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPuzzleCategoryTabs() {
    final categories = [
      "Solar System",
      "Human Body",
      "Animal Kingdom",
      "Math Basics",
      "Scientists",
      "Geometry",
      "Starbooks"
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildTabButton(
              label: category,
              isSelected: isSelected,
              onTap: () {
                setState(() => selectedCategory = category);
                _loadLeaderboard();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final currentColor = _getCurrentGameColor();
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? currentColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? currentColor : Colors.grey.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: currentColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Poppins',
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  // Fetch user category and address from homepage API
  Future<Map<String, String>> _getUserDetails() async {
    try {
      final url = "$baseUrl/api/homepage/${widget.currentUserId}";
      final response = await http.get(Uri.parse(url));

      if (kDebugMode) {
        debugPrint('Fetching user details from: $url');
        debugPrint('Response status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final user = data['user'];

          // Get location names
          final city = user['city'] ?? 'Unknown City';
          final province = user['province'] ?? 'Unknown Province';
          final region = user['region'] ?? 'Unknown Region';

          // Format address like in edit_profile: "City, Province, Region"
          final address = "$city, $province, $region";

          // Get category from the same response
          final category = user['category'] ?? 'N/A';

          if (kDebugMode) {
            debugPrint('Category: $category');
            debugPrint('Address: $address');
          }

          return {
            'category': category,
            'address': address,
          };
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching user details: $e');
      }
    }

    return {
      'category': 'N/A',
      'address': 'N/A',
    };
  }

  // Get current game color
  Color _getCurrentGameColor() {
    switch (selectedGame) {
      case "whiz_memory_match":
        return const Color(0xFF656BE6); // Purple/Blue
      case "whiz_challenge":
        return const Color(0xFFFDD000); // Yellow
      case "whiz_battle":
        return const Color(0xFFC571E2); // Pink/Purple
      case "whiz_puzzle":
        return const Color(0xFFE6833A); // Orange
      default:
        return const Color(0xFF046EB8); // Default Blue
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getCurrentGameColor(), // Dynamic background color
      body: SafeArea(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          color: _getCurrentGameColor(),
          child: Row(
            children: [
              // Left side - Rankings (70%)
              Expanded(
                flex: 7,
                child: _buildRankingsPanel(),
              ),

              // Right side - User Stats (30%)
              Expanded(
                flex: 3,
                child: _buildUserStatsPanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankingsPanel() {
    return Column(
      children: [
        // LEADERBOARD Title - Outside the white container
        Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: const Text(
            "LEADERBOARD",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),

        // White container with rankings
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Game selector
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildGameButton("Whiz Challenge", "whiz_challenge"),
                    _buildGameButton("Whiz Battle", "whiz_battle"),
                    _buildGameButton("Memory Match", "whiz_memory_match"),
                    _buildGameButton("Whiz Puzzle", "whiz_puzzle"),
                  ],
                ),

                const SizedBox(height: 16),

                // Racing track divider
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getCurrentGameColor(),
                        const Color(0xFFFDD000),
                        _getCurrentGameColor(),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 16),

                // Filter tabs - Above the table header
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _buildFilterTabs(),
                ),

                const SizedBox(height: 16),

                // Table Header
                _buildTableHeader(),

                const SizedBox(height: 12),

                // Rankings list
                Expanded(
                  child: isLoading
                      ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF046EB8)),
                  )
                      : leaderboardData.isEmpty
                      ? const Center(
                    child: Text(
                      "No rankings available",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                      : ListView.builder(
                    itemCount: leaderboardData.length,
                    itemBuilder: (context, index) {
                      final player = leaderboardData[index];
                      final rank = index + 1;
                      final playerId = _extractId(player['player_id'] ?? player['id'] ?? player['_id']);
                      final isCurrentUser = playerId == widget.currentUserId;

                      return _buildRankingRow(player, rank, isCurrentUser);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameButton(String label, String gameId) {
    final isSelected = selectedGame == gameId;

    // Get the color based on game type
    Color getGameColor() {
      switch (gameId) {
        case "whiz_memory_match":
          return const Color(0xFF656BE6); // Purple/Blue
        case "whiz_challenge":
          return const Color(0xFFFDD000); // Yellow
        case "whiz_battle":
          return const Color(0xFFC571E2); // Pink/Purple
        case "whiz_puzzle":
          return const Color(0xFFE6833A); // Orange
        default:
          return const Color(0xFF046EB8);
      }
    }

    final gameColor = getGameColor();

    return ElevatedButton(
      onPressed: () {
        setState(() => selectedGame = gameId);
        _loadLeaderboard();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? gameColor : Colors.white,
        foregroundColor: Colors.white,
        elevation: isSelected ? 8 : 0,
        shadowColor: gameColor.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(
            color: isSelected ? gameColor : Colors.grey.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    final currentColor = _getCurrentGameColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [currentColor, currentColor.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 50, child: Text("RANK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
          const SizedBox(width: 16),
          // All games show "USERNAME"
          const Expanded(
              flex: 3,
              child: Text(
                  "USERNAME",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
              )
          ),
          if (selectedGame == "whiz_challenge" || selectedGame == "whiz_battle") ...[
            const Expanded(child: Center(child: Text("EASY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
            const Expanded(child: Center(child: Text("AVERAGE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
            const Expanded(child: Center(child: Text("DIFFICULT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
            const Expanded(child: Center(child: Text("TOTAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
          ] else if (selectedGame == "whiz_memory_match") ...[
            const Expanded(child: Center(child: Text("FASTEST TIME", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
          ] else if (selectedGame == "whiz_puzzle") ...[
            const Expanded(child: Center(child: Text("TIME", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
          ],
        ],
      ),
    );
  }

  Widget _buildRankingRow(Map<String, dynamic> player, int rank, bool isCurrentUser) {
    Color cardColor = isCurrentUser
        ? const Color(0xFFFDD000).withValues(alpha: 0.2)
        : (rank % 2 == 0 ? Colors.grey.withValues(alpha: 0.05) : Colors.white);

    Color borderColor = isCurrentUser
        ? const Color(0xFFFDD000)
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isCurrentUser ? 3 : 0),
        boxShadow: isCurrentUser
            ? [
          BoxShadow(
            color: const Color(0xFFFDD000).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: Row(
        children: [
          // Rank badge
          SizedBox(
            width: 50,
            child: _buildRankBadge(rank),
          ),
          const SizedBox(width: 16),

          // Avatar and name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
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
                        return const Icon(Icons.person, color: Color(0xFF046EB8));
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player['username'] ?? player['player_username'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF046EB8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isCurrentUser)
                        const Text(
                          "YOU",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFDD000),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats columns
          if (selectedGame == "whiz_challenge" || selectedGame == "whiz_battle") ...[
            Expanded(child: _buildStatCell("${player['easy_count'] ?? 0}", const Color(0xFF1D9358))),
            Expanded(child: _buildStatCell("${player['average_count'] ?? 0}", const Color(0xFF046EB8))),
            Expanded(child: _buildStatCell("${player['difficult_count'] ?? 0}", const Color(0xFFBD442E))),
            Expanded(child: _buildStatCell("${player['total_rewards'] ?? 0}", const Color(0xFFFDD000), bold: true)),
          ] else if (selectedGame == "whiz_memory_match" || selectedGame == "whiz_puzzle") ...[
            // Memory Match and Whiz Puzzle - only show time
            Expanded(child: _buildStatCell(_formatTime(player['time_seconds'] ?? 0), const Color(0xFF046EB8))),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCell(String value, Color color, {bool bold = false}) {
    return Center(
      child: Text(
        value,
        style: TextStyle(
          fontSize: bold ? 18 : 16,
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bgColor = _getRankColor(rank);
    IconData? medalIcon;

    if (rank <= 3) {
      medalIcon = Icons.emoji_events;
    }

    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: medalIcon != null
            ? Icon(medalIcon, color: Colors.white, size: 24)
            : Text(
          "$rank",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
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
        return const Color(0xFF046EB8); // Blue
    }
  }

  Widget _buildUserStatsPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 20, 20, 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFDD000).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // User avatar
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFDD000).withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFDD000), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFDD000).withValues(alpha: 0.5),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    widget.userAvatar,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, size: 60, color: Color(0xFF046EB8));
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            widget.username,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF046EB8),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Category
          FutureBuilder<Map<String, String>>(
            future: _getUserDetails(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Column(
                  children: [
                    Text(
                      snapshot.data!['category'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: "Poppins",
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snapshot.data!['address'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          const SizedBox(height: 24),

          // Stats
          Expanded(
            child: currentUserStats == null
                ? const Center(
              child: Text(
                "No stats available",
                style: TextStyle(color: Colors.grey),
              ),
            )
                : _buildUserStatsDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatsDetails() {
    if (selectedGame == "whiz_challenge" || selectedGame == "whiz_battle") {
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildStatCard(
              Icons.stars,
              "Total Rewards",
              "${currentUserStats!['total_rewards'] ?? 0}",
              const Color(0xFFFDD000),
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              Icons.circle,
              "Easy Wins",
              "${currentUserStats!['easy_count'] ?? 0}",
              const Color(0xFF1D9358),
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              Icons.circle,
              "Average Wins",
              "${currentUserStats!['average_count'] ?? 0}",
              const Color(0xFF046EB8),
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              Icons.circle,
              "Difficult Wins",
              "${currentUserStats!['difficult_count'] ?? 0}",
              const Color(0xFFBD442E),
            ),
          ],
        ),
      );
    } else {
      final time = currentUserStats!['time_seconds'] ?? 0;
      final moves = currentUserStats!['moves'] ?? 0;
      final username = currentUserStats!['player_username'] ?? 'Unknown';

      return SingleChildScrollView(
        child: Column(
          children: [
            _buildStatCard(
              Icons.timer,
              "Fastest Time",
              _formatTime(time),
              const Color(0xFFFDD000),
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              Icons.touch_app,
              "Moves",
              "$moves",
              const Color(0xFF046EB8),
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              Icons.person,
              "Player",
              username,
              const Color(0xFF1D9358),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}