import 'package:flutter/material.dart';

class Leaderboard extends StatefulWidget {
  const Leaderboard({super.key});

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  String selectedMode = "challenge"; // default mode

  // Dummy leaderboard data
  final List<Map<String, dynamic>> challengeData = [
    {
      "username": "ronald",
      "avatar": "assets/images-avatars/Brainy.png",
      "rewards": 12,
      "easy": 6,
      "avg": 3,
      "diff": 3,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "carla",
      "avatar": "assets/images-avatars/Girl.png",
      "rewards": 11,
      "easy": 6,
      "avg": 2,
      "diff": 1,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "clarisse",
      "avatar": "assets/images-avatars/Twirky.png",
      "rewards": 9,
      "easy": 3,
      "avg": 3,
      "diff": 3,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "robert",
      "avatar": "assets/images-avatars/Sneaky-Snake.png",
      "rewards": 8,
      "easy": 4,
      "avg": 2,
      "diff": 2,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "jerome",
      "avatar": "assets/images-avatars/Brainy.png",
      "rewards": 7,
      "easy": 4,
      "avg": 2,
      "diff": 1,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "ariel",
      "avatar": "assets/images-avatars/Twirky.png",
      "rewards": 5,
      "easy": 3,
      "avg": 2,
      "diff": 0,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "hannah",
      "avatar": "assets/images-avatars/Girl.png",
      "rewards": 4,
      "easy": 2,
      "avg": 2,
      "diff": 0,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "rico",
      "avatar": "assets/images-avatars/Sneaky-Snake.png",
      "rewards": 3,
      "easy": 2,
      "avg": 1,
      "diff": 0,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "marie",
      "avatar": "assets/images-avatars/Astronaut.png",
      "rewards": 3,
      "easy": 3,
      "avg": 0,
      "diff": 0,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "jude",
      "avatar": "assets/images-avatars/Astronaut.png",
      "rewards": 2,
      "easy": 1,
      "avg": 1,
      "diff": 0,
      "last": "05/23/2025 15:45",
    },
  ];

  final List<Map<String, dynamic>> battleData = [
    {
      "username": "leo",
      "avatar": "assets/images-avatars/Twirky.png",
      "rewards": 15,
      "easy": 7,
      "avg": 4,
      "diff": 4,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "mia",
      "avatar": "assets/images-avatars/Whiz-Busy.png",
      "rewards": 10,
      "easy": 4,
      "avg": 3,
      "diff": 3,
      "last": "05/23/2025 15:45",
    },
  ];

  List<Map<String, dynamic>> get leaderboardData {
    return selectedMode == "challenge" ? challengeData : battleData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF94D2FD),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar with Toggle Buttons and Action Buttons
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Toggle Buttons
                        Row(
                          children: [
                            _buildModeButton("Whiz Challenge", "challenge"),
                            const SizedBox(width: 12),
                            _buildModeButton("Whiz Battle", "battle"),
                          ],
                        ),
                        // Sort and Filter Buttons
                        Row(
                          children: [
                            _buildIconButton(Icons.sort, "Sort"),
                            const SizedBox(width: 8),
                            _buildIconButton(
                              Icons.filter_alt_outlined,
                              "Filter",
                            ),
                            const SizedBox(width: 8),
                            _buildIconButton(Icons.refresh, null),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Inner centered leaderboard container
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: const [
                                SizedBox(width: 50),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "Username",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "Total Rewards",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "Easy",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF1D9358),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "Average",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF046EB8),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "Difficult",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFBD442E),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "Last Claim",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Leaderboard Rows
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: Colors.grey.shade300),
                                  right: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                  bottom: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: ListView.builder(
                                itemCount: leaderboardData.length,
                                itemBuilder: (context, index) {
                                  final player = leaderboardData[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom:
                                            index < leaderboardData.length - 1
                                            ? BorderSide(
                                                color: Colors.grey.shade300,
                                              )
                                            : BorderSide.none,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        _buildRankBadge(index + 1),
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundImage: AssetImage(
                                                  player["avatar"],
                                                ),
                                                radius: 18,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                player["username"],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            "${player["rewards"]}",
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            "${player["easy"]}",
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            "${player["avg"]}",
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            "${player["diff"]}",
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            player["last"],
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for mode toggle buttons
  Widget _buildModeButton(String label, String mode) {
    final bool isSelected = selectedMode == mode;
    return ElevatedButton(
      onPressed: () => setState(() => selectedMode = mode),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xff046EB8) : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(
            color: isSelected ? const Color(0xff046EB8) : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  // Helper for icon buttons (Sort, Filter, Refresh)
  Widget _buildIconButton(IconData icon, String? label) {
    return OutlinedButton(
      onPressed: () {
        // Add your functionality here
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: BorderSide(color: Colors.grey.shade400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: label != null
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
            : const EdgeInsets.all(10),
        minimumSize: Size.zero,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  // Helper for rank badge
  Widget _buildRankBadge(int rank) {
    Color? bgColor;
    switch (rank) {
      case 1:
        bgColor = const Color(0xFFFFD700); // Gold
        break;
      case 2:
        bgColor = const Color(0xFFC0C0C0); // Silver
        break;
      case 3:
        bgColor = const Color(0xFFCD7F32); // Bronze
        break;
      default:
        bgColor = Colors.black;
    }
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Text(
        "$rank",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
