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
      "totalRewards": 12,
      "easy": 6,
      "avg": 3,
      "diff": 3,
      "last": "05/23/2025 15:45",
      "status": "claimed",
    },
    {
      "username": "carla",
      "avatar": "assets/images-avatars/Girl.png",
      "totalRewards": 11,
      "easy": 6,
      "avg": 2,
      "diff": 1,
      "last": "05/23/2025 15:45",
      "status": "pending",
    },
    {
      "username": "clarisse",
      "avatar": "assets/images-avatars/Twirky.png",
      "totalRewards": 9,
      "easy": 3,
      "avg": 3,
      "diff": 3,
      "last": "05/23/2025 15:45",
      "status": "claimed",
    },
    {
      "username": "robert",
      "avatar": "assets/images-avatars/Sneaky-Snake.png",
      "totalRewards": 8,
      "easy": 4,
      "avg": 2,
      "diff": 2,
      "last": "05/23/2025 15:45",
      "status": "pending",
    },
    {
      "username": "jerome",
      "avatar": "assets/images-avatars/Brainy.png",
      "totalRewards": 7,
      "easy": 4,
      "avg": 2,
      "diff": 1,
      "last": "05/23/2025 15:45",
      "status": "claimed",
    },
    {
      "username": "ariel",
      "avatar": "assets/images-avatars/Twirky.png",
      "totalRewards": 5,
      "easy": 3,
      "avg": 2,
      "diff": 0,
      "last": "05/23/2025 15:45",
      "status": "pending",
    },
    {
      "username": "hannah",
      "avatar": "assets/images-avatars/Girl.png",
      "totalRewards": 4,
      "easy": 2,
      "avg": 2,
      "diff": 0,
      "last": "05/23/2025 15:45",
      "status": "claimed",
    },
    {
      "username": "rico",
      "avatar": "assets/images-avatars/Sneaky-Snake.png",
      "totalRewards": 3,
      "easy": 2,
      "avg": 1,
      "diff": 0,
      "last": "05/23/2025 15:45",
      "status": "pending",
    },
    {
      "username": "marie",
      "avatar": "assets/images-avatars/Astronaut.png",
      "totalRewards": 3,
      "easy": 3,
      "avg": 0,
      "diff": 0,
      "last": "05/23/2025 15:45",
      "status": "claimed",
    },
    {
      "username": "jude",
      "avatar": "assets/images-avatars/Astronaut.png",
      "totalRewards": 2,
      "easy": 1,
      "avg": 1,
      "diff": 0,
      "last": "05/23/2025 15:45",
      "status": "pending",
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
      "status": "claimed",
    },
    {
      "username": "mia",
      "avatar": "assets/images-avatars/Whiz-Busy.png",
      "rewards": 1200,
      "easy": 4,
      "avg": 3,
      "diff": 3,
      "last": "05/23/2025 15:45",
      "status": "pending",
    },
    {
      "username": "alex",
      "avatar": "assets/images-avatars/Brainy.png",
      "rewards": 1050,
      "easy": 5,
      "avg": 3,
      "diff": 2,
      "last": "05/22/2025 18:30",
      "status": "claimed",
    },
    {
      "username": "sarah",
      "avatar": "assets/images-avatars/Girl.png",
      "rewards": 890,
      "easy": 4,
      "avg": 2,
      "diff": 2,
      "last": "05/22/2025 14:15",
      "status": "pending",
    },
    {
      "username": "david",
      "avatar": "assets/images-avatars/Sneaky-Snake.png",
      "rewards": 750,
      "easy": 3,
      "avg": 2,
      "diff": 1,
      "last": "05/21/2025 20:45",
      "status": "claimed",
    },
  ];

  List<Map<String, dynamic>> get leaderboardData {
    return selectedMode == "challenge" ? challengeData : battleData;
  }

  void _refreshData() {
    setState(() {
      // Reload the data (in a real app, you'd fetch from backend)
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Leaderboard data refreshed'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _exportData() {
    Map<String, bool> selectedLeaderboards = {
      'challenge': false,
      'battle': false,
    };
    bool selectAll = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export Leaderboard Data',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select which leaderboard(s) to export',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select Leaderboard',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text(
                      'Badges',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                    ),
                    secondary: const Icon(
                      Icons.emoji_events,
                      color: Color(0xFF046EB8),
                    ),
                    value: selectedLeaderboards['challenge'],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedLeaderboards['challenge'] = value ?? false;
                        selectAll = selectedLeaderboards['challenge']! &&
                            selectedLeaderboards['battle']!;
                      });
                    },
                    activeColor: const Color(0xFF046EB8),
                  ),
                  CheckboxListTile(
                    title: const Text(
                      'Stars',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                    ),
                    secondary: const Icon(
                      Icons.sports_esports,
                      color: Color(0xFF046EB8),
                    ),
                    value: selectedLeaderboards['battle'],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedLeaderboards['battle'] = value ?? false;
                        selectAll = selectedLeaderboards['challenge']! &&
                            selectedLeaderboards['battle']!;
                      });
                    },
                    activeColor: const Color(0xFF046EB8),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Export Format',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _performExportFromDialog(
                                selectedLeaderboards, 'CSV');
                          },
                          icon: const Icon(Icons.file_upload_outlined, size: 18),
                          label: const Text(
                            'CSV',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF046EB8),
                            side: const BorderSide(color: Color(0xFF046EB8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _performExportFromDialog(
                                selectedLeaderboards, 'Excel');
                          },
                          icon: const Icon(Icons.file_upload_outlined, size: 18),
                          label: const Text(
                            'Excel',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF046EB8),
                            side: const BorderSide(color: Color(0xFF046EB8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _performExportFromDialog(
                                selectedLeaderboards, 'PDF');
                          },
                          icon: const Icon(Icons.file_upload_outlined, size: 18),
                          label: const Text(
                            'PDF',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF046EB8),
                            side: const BorderSide(color: Color(0xFF046EB8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: Color(0xFF046EB8),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Color(0xFF046EB8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _performExportFromDialog(
      Map<String, bool> selectedLeaderboards, String format) {
    if (!selectedLeaderboards['challenge']! &&
        !selectedLeaderboards['battle']!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one leaderboard'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.pop(context);

    String leaderboardType;
    if (selectedLeaderboards['challenge']! &&
        selectedLeaderboards['battle']!) {
      leaderboardType = 'both';
    } else if (selectedLeaderboards['challenge']!) {
      leaderboardType = 'challenge';
    } else {
      leaderboardType = 'battle';
    }

    _performExport(format, leaderboardType);
  }

  void _selectExportFormat(String leaderboardType) {
    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Export Format',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Exporting ${_getLeaderboardLabel(leaderboardType)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.file_upload_outlined, color: Color(0xFF046EB8)),
                        title: const Text(
                          'Export as CSV',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        ),
                        onTap: () {
                          _performExport('CSV', leaderboardType);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.file_upload_outlined, color: Color(0xFF046EB8)),
                        title: const Text(
                          'Export as Excel',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        ),
                        onTap: () {
                          _performExport('Excel', leaderboardType);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.file_upload_outlined, color: Color(0xFF046EB8)),
                        title: const Text(
                          'Export as PDF',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        ),
                        onTap: () {
                          _performExport('PDF', leaderboardType);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: Color(0xFF046EB8),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Color(0xFF046EB8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  String _getLeaderboardLabel(String type) {
    switch (type) {
      case 'challenge':
        return 'Badges';
      case 'battle':
        return 'Stars';
      case 'both':
        return 'Both Leaderboards';
      default:
        return '';
    }
  }

  void _performExport(String format, String leaderboardType) {
    Navigator.pop(context);

    String exportContent = _generateExportContent(format, leaderboardType);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Exporting ${_getLeaderboardLabel(leaderboardType)} as $format...'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            _showExportPreview(format, exportContent, leaderboardType);
          },
        ),
      ),
    );
  }

  String _generateExportContent(String format, String leaderboardType) {
    if (format == 'CSV') {
      StringBuffer csv = StringBuffer();

      if (leaderboardType == 'challenge' || leaderboardType == 'both') {
        csv.writeln('=== BADGES LEADERBOARD ===');
        csv.writeln('Rank,Username,Total Rewards,Easy,Average,Difficult,Last Claim,Status');
        for (int i = 0; i < challengeData.length; i++) {
          var player = challengeData[i];
          csv.writeln(
              '${i + 1},${player['username']},${player['totalRewards']},'
                  '${player['easy']},${player['avg']},${player['diff']},'
                  '${player['last']},${player['status']}');
        }
        if (leaderboardType == 'both') {
          csv.writeln('');
        }
      }

      if (leaderboardType == 'battle' || leaderboardType == 'both') {
        csv.writeln('=== STARS LEADERBOARD ===');
        csv.writeln('Rank,Username,Total Stars,Last Battle,Status');
        for (int i = 0; i < battleData.length; i++) {
          var player = battleData[i];
          csv.writeln('${i + 1},${player['username']},${player['rewards']},${player['last']},${player['status']}');
        }
      }

      return csv.toString();
    }
    return 'Export data for $format - ${_getLeaderboardLabel(leaderboardType)}';
  }

  void _showExportPreview(String format, String content, String leaderboardType) {
    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 600,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Preview ($format)',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getLeaderboardLabel(leaderboardType),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          content,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF046EB8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
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
            // Top controls with buttons on opposite sides
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - Mode buttons
                Row(
                  children: [
                    _buildModeButton("Badges", "challenge"),
                    const SizedBox(width: 12),
                    _buildModeButton("Stars", "battle"),
                  ],
                ),
                // Right side - Action buttons
                Row(
                  children: [
                    IconButton(
                      onPressed: _exportData,
                      icon: const Icon(Icons.file_upload_outlined, size: 20),
                      style: IconButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: const CircleBorder(),
                      ),
                      tooltip: 'Export Data',
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _refreshData,
                      icon: const Icon(Icons.refresh, size: 20),
                      style: IconButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: const CircleBorder(),
                      ),
                      tooltip: 'Refresh',
                    ),
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
                    child: selectedMode == "challenge"
                        ? Row(
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
                            "Total Rewards",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Easy",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              color: Color(0xFF27AE60),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Average",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              color: Color(0xFF4285F4),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Difficult",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              color: Color(0xFFE74C3C),
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
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Status",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    )
                        : Row(
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
                            "Last Updated",
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
                            child: selectedMode == "challenge"
                                ? _buildChallengeRow(player, index)
                                : _buildBattleRow(player, index),
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

  Widget _buildChallengeRow(Map<String, dynamic> player, int index) {
    return Row(
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
                    errorBuilder: (context, error, stackTrace) {
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
          child: Text(
            "${player["totalRewards"]}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "${player["easy"]}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "${player["avg"]}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "${player["diff"]}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
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
              fontFamily: 'Poppins',
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Container(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: player["status"] == "claimed"
                    ? const Color(0xFF27AE60).withValues(alpha: 0.1)
                    : const Color(0xFFF39C12).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                player["status"],
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: player["status"] == "claimed"
                      ? const Color(0xFF27AE60)
                      : const Color(0xFFF39C12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBattleRow(Map<String, dynamic> player, int index) {
    return Row(
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
                    errorBuilder: (context, error, stackTrace) {
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

  Widget _buildActionButton(IconData icon, String? label,
      VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
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
