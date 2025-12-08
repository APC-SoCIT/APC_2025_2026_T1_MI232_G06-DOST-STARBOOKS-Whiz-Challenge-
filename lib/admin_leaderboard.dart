import 'package:flutter/material.dart';

class AdminLeaderboard extends StatefulWidget {
  const AdminLeaderboard({super.key});

  @override
  State<AdminLeaderboard> createState() => _AdminLeaderboardState();
}

class _AdminLeaderboardState extends State<AdminLeaderboard> {
  String selectedMode = "challenge";

  // Leaderboard data
  final List<Map<String, dynamic>> challengeData = [
    {
      "username": "ronald",
      "avatar": "assets/images-avatars/Brainy.png",
      "rewards": 1035,
      "easy": 6,
      "avg": 3,
      "diff": 3,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "carla",
      "avatar": "assets/images-avatars/Girl.png",
      "rewards": 939,
      "easy": 6,
      "avg": 2,
      "diff": 1,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "clarisse",
      "avatar": "assets/images-avatars/Twirky.png",
      "rewards": 872,
      "easy": 3,
      "avg": 3,
      "diff": 3,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "robert",
      "avatar": "assets/images-avatars/Sneaky-Snake.png",
      "rewards": 761,
      "easy": 4,
      "avg": 2,
      "diff": 2,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "jerome",
      "avatar": "assets/images-avatars/Brainy.png",
      "rewards": 708,
      "easy": 4,
      "avg": 2,
      "diff": 1,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "ariel",
      "avatar": "assets/images-avatars/Twirky.png",
      "rewards": 631,
      "easy": 3,
      "avg": 2,
      "diff": 0,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "hannah",
      "avatar": "assets/images-avatars/Girl.png",
      "rewards": 527,
      "easy": 2,
      "avg": 2,
      "diff": 0,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "rico",
      "avatar": "assets/images-avatars/Sneaky-Snake.png",
      "rewards": 504,
      "easy": 2,
      "avg": 1,
      "diff": 0,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "marie",
      "avatar": "assets/images-avatars/Astronaut.png",
      "rewards": 469,
      "easy": 3,
      "avg": 0,
      "diff": 0,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "jude",
      "avatar": "assets/images-avatars/Astronaut.png",
      "rewards": 321,
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
      "rewards": 1500,
      "easy": 7,
      "avg": 4,
      "diff": 4,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "mia",
      "avatar": "assets/images-avatars/Whiz-Busy.png",
      "rewards": 1200,
      "easy": 4,
      "avg": 3,
      "diff": 3,
      "last": "05/23/2025 15:45",
    },
    {
      "username": "alex",
      "avatar": "assets/images-avatars/Brainy.png",
      "rewards": 1050,
      "easy": 5,
      "avg": 3,
      "diff": 2,
      "last": "05/22/2025 18:30",
    },
    {
      "username": "sarah",
      "avatar": "assets/images-avatars/Girl.png",
      "rewards": 890,
      "easy": 4,
      "avg": 2,
      "diff": 2,
      "last": "05/22/2025 14:15",
    },
    {
      "username": "david",
      "avatar": "assets/images-avatars/Sneaky-Snake.png",
      "rewards": 750,
      "easy": 3,
      "avg": 2,
      "diff": 1,
      "last": "05/21/2025 20:45",
    },
  ];

  List<Map<String, dynamic>> get leaderboardData {
    return selectedMode == "challenge" ? challengeData : battleData;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF94D2FD),
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildModeButton("Whiz Challenge", "challenge"),
                    const SizedBox(width: 12),
                    _buildModeButton("Whiz Battle", "battle"),
                  ],
                ),
                Row(
                  children: [
                    _buildActionButton(Icons.file_upload_outlined, "Export"),
                    const SizedBox(width: 12),
                    _buildActionButton(Icons.refresh, null),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Table
            Expanded(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
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
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Total Stars",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Last Battle",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Rows
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade300),
                          right: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(8),
                        ),
                      ),
                      child: ListView.builder(
                        itemCount: leaderboardData.length,
                        itemBuilder: (context, index) {
                          final player = leaderboardData[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: index % 2 == 0
                                  ? Colors.white
                                  : Colors.grey.shade50,
                              border: Border(
                                bottom: index < leaderboardData.length - 1
                                    ? BorderSide(color: Colors.grey.shade300)
                                    : BorderSide.none,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24,
                            ),
                            child: Row(
                              children: [
                                _buildRankBadge(index + 1),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF046EB8),
                                            width: 2,
                                          ),
                                          color: Colors.grey.shade200,
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            player["avatar"],
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.person,
                                                    color: Color(0xFF046EB8),
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        player["username"],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Color(0xFFFDD000),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${player["rewards"]}",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    player["last"],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                      color: Colors.black87,
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
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(String label, String mode) {
    final bool isSelected = selectedMode == mode;
    return ElevatedButton(
      onPressed: () => setState(() => selectedMode = mode),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF046EB8) : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(
            color: isSelected ? const Color(0xFF046EB8) : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String? label) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: BorderSide(color: Colors.grey.shade400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: label != null
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
            : const EdgeInsets.all(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bgColor;
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
        bgColor = const Color(0xFF34495E);
    }

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        "$rank",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
