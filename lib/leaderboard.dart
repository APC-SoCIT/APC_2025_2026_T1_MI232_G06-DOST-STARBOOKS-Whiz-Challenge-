import 'audio_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

// ─── Brand colours ────────────────────────────────────────────────────────────
// Homepage blue palette  ↓
const _navy      = Color(0xFF1560BD);   // main page background – vivid homepage blue
const _navy2     = Color(0xFF1252A8);   // slightly deeper for headers / profile bar
const _blue      = Color(0xFF1A6FD4);   // lighter surface accent
const _gold      = Color(0xFFF7C600);
const _goldDark  = Color(0xFFE6B400);
const _easy      = Color(0xFF22C55E);
const _average   = Color(0xFFF59E0B);
const _difficult = Color(0xFFEF4444);
const _purple    = Color(0xFF656BE6);
const _orange    = Color(0xFFE6833A);
const _cardBg    = Color(0x18FFFFFF);   // white ~10% — pops more on mid-blue
const _cardBorder= Color(0x26FFFFFF);   // white ~15%

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
  final String baseUrl = "http://localhost:8000";

  String selectedGame       = "badges";
  String selectedDifficulty = "EASY";
  String selectedCategory   = "Solar System";
  bool   isLoading          = true;

  int    _playerStars    = 0;
  String _playerTier     = 'Beginner';
  String _playerTierIcon = '⭐';

  Map<String, dynamic>? _memoryMatchStats;
  Map<String, dynamic>? _puzzleStats;

  List<Map<String, dynamic>> leaderboardData = [];

  int _currentBadgeDifficultyIndex  = 0;
  int _currentMemoryDifficultyIndex = 0;
  int _currentPuzzleDifficultyIndex = 0;
  int _currentPuzzleCategoryIndex   = 0;

  final List<String> _badgeDifficulties        = ['Easy', 'Average', 'Difficult'];
  final List<String> _gameDifficulties         = ['EASY', 'AVERAGE', 'DIFFICULT'];
  final List<String> _gameDifficultiesDisplay  = ['Easy', 'Average', 'Difficult'];
  final List<String> _puzzleCategories = [
    "Solar System", "Scientists", "The Human Body",
    "Animals", "Geometry", "Starbooks",
  ];
  final List<String> _puzzleCategoriesShort = [
    'Solar', 'Sci.', 'Body', 'Anim.', 'Geo.', 'Books',
  ];

  Map<String, dynamic> _badgeCounts = {
    'easy_count': 0, 'average_count': 0, 'difficult_count': 0,
  };

  final PageController _badgePageController = PageController();

  // ─── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
    _loadPlayerStars();
    _loadBadgeData();
    _loadSidePanelStats();
  }

  @override
  void dispose() {
    _badgePageController.dispose();
    super.dispose();
  }

  // ─── data loaders ───────────────────────────────────────────────────────────

  Future<void> _loadPlayerStars() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/players/${widget.currentUserId}/stars'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _playerStars    = data['data']?['total_stars']             ?? 0;
            _playerTier     = data['data']?['current_tier']?['tier']   ?? 'Beginner';
            _playerTierIcon = data['data']?['current_tier']?['icon']   ?? '⭐';
          });
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading player stars: $e');
    }
  }

  Future<void> _loadBadgeData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/players/${widget.currentUserId}/badges'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _badgeCounts = {
              'easy_count':      data['easy_count']      ?? 0,
              'average_count':   data['average_count']   ?? 0,
              'difficult_count': data['difficult_count'] ?? 0,
            };
          });
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading badge data: $e');
    }
  }

  Future<void> _loadSidePanelStats() async {
    await _fetchMemoryMatchStat();
    await _fetchPuzzleStat();
  }

  Future<void> _fetchMemoryMatchStat() async {
    final difficulty = _gameDifficulties[_currentMemoryDifficultyIndex];
    try {
      final response = await http.get(Uri.parse(
        '$baseUrl/api/game/fastest-time/${widget.currentUserId}/memory_match/$difficulty',
      ));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) setState(() => _memoryMatchStats = data['data']);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading memory match stat: $e');
    }
  }

  Future<void> _fetchPuzzleStat() async {
    final difficulty = _gameDifficulties[_currentPuzzleDifficultyIndex];
    final category   = _puzzleCategories[_currentPuzzleCategoryIndex];
    try {
      final response = await http.get(Uri.parse(
        '$baseUrl/api/game/fastest-time/${widget.currentUserId}/puzzle/$difficulty'
            '?category=${Uri.encodeComponent(category)}',
      ));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) setState(() => _puzzleStats = data['data']);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading puzzle stat: $e');
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() => isLoading = true);
    try {
      switch (selectedGame) {
        case "badges":            await _loadBadgesLeaderboard();      break;
        case "stars":             await _loadStarsLeaderboard();       break;
        case "whiz_memory_match":
        case "whiz_puzzle":       await _loadFastestTimeLeaderboard(); break;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading leaderboard: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadBadgesLeaderboard() async {
    final url = "$baseUrl/api/leaderboard?mode=challenge&limit=20";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            leaderboardData =
                List<Map<String, dynamic>>.from(data['users'] ?? []).take(20).toList();
          });
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error in _loadBadgesLeaderboard: $e');
    }
  }

  Future<void> _loadStarsLeaderboard() async {
    final url = "$baseUrl/api/stars/leaderboard?limit=20";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            leaderboardData =
                List<Map<String, dynamic>>.from(data['data'] ?? []).take(20).toList();
          });
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error in _loadStarsLeaderboard: $e');
    }
  }

  Future<void> _loadFastestTimeLeaderboard() async {
    final gameType = selectedGame == "whiz_memory_match" ? "memory_match" : "puzzle";
    String url =
        "$baseUrl/api/game/fastest-times/leaderboard?game_type=$gameType&difficulty=$selectedDifficulty&limit=50";
    if (gameType == "puzzle") {
      url += "&category=${Uri.encodeComponent(selectedCategory)}";
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            leaderboardData = List<Map<String, dynamic>>.from(data['data'] ?? []);
          });
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error in _loadFastestTimeLeaderboard: $e');
    }
  }

  // ─── helpers ────────────────────────────────────────────────────────────────

  String _extractId(dynamic idValue) {
    if (idValue is Map) {
      if (idValue.containsKey('\$oid')) return idValue['\$oid'].toString();
      if (idValue.containsKey('oid'))  return idValue['oid'].toString();
    }
    return idValue?.toString() ?? '';
  }

  String _formatTime(int? seconds) {
    if (seconds == null) return '--:--';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  Color _getCurrentGameColor() {
    switch (selectedGame) {
      case "badges":            return _gold;
      case "stars":             return _average;
      case "whiz_memory_match": return _purple;
      case "whiz_puzzle":       return _orange;
      default:                  return _gold;
    }
  }

  Color _getButtonColor(String gameId) {
    switch (gameId) {
      case "badges":            return _gold;
      case "stars":             return _average;
      case "whiz_memory_match": return _purple;
      case "whiz_puzzle":       return _orange;
      default:                  return _gold;
    }
  }

  String _getBadgeImagePath(int _) {
    switch (_currentBadgeDifficultyIndex) {
      case 0:  return 'assets/images-badges/whiz-ready.png';
      case 1:  return 'assets/images-badges/whiz-happy.png';
      case 2:  return 'assets/images-badges/whiz-achiever.png';
      default: return 'assets/images-badges/whiz-ready.png';
    }
  }

  int _getBadgeCount() {
    switch (_currentBadgeDifficultyIndex) {
      case 0:  return _badgeCounts['easy_count']      ?? 0;
      case 1:  return _badgeCounts['average_count']   ?? 0;
      case 2:  return _badgeCounts['difficult_count'] ?? 0;
      default: return 0;
    }
  }

  // ─── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1560BD),   // exact homepage blue
      body: SafeArea(
        child: Row(
          children: [
            Expanded(flex: 7, child: _buildRankingsPanel()),
            Expanded(flex: 3, child: _buildUserStatsPanel()),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEFT – Rankings panel
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRankingsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Page header ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'LEADERBOARD',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'See how you rank against other Whiz Champions!',
                    style: TextStyle(fontSize: 12, color: Color(0x99FFFFFF)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Main card ────────────────────────────────────────────────────────
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            ),
            child: Column(
              children: [
                // ── Tabs + refresh ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildGameButton("🏅  Badges", "badges"),
                          _buildGameButton("⭐  Stars",  "stars"),
                        ],
                      ),
                      Row(
                        children: [
                          _buildFilterDropdowns(),
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Refresh',
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () async {
                                  try { await AudioService().playClickSound(); } catch (_) {}
                                  _loadLeaderboard();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Refreshing leaderboard…'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.refresh_rounded,
                                      size: 20, color: Color(0xFF64748B)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Accent line ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: _getCurrentGameColor(),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTableHeader(),
                ),
                const SizedBox(height: 10),

                // ── Rows ────────────────────────────────────────────────────
                Expanded(
                  child: isLoading
                      ? Center(
                    child: CircularProgressIndicator(
                      color: _getCurrentGameColor(), strokeWidth: 2.5,
                    ),
                  )
                      : leaderboardData.isEmpty
                      ? const Center(
                    child: Text(
                      'No rankings available yet.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    itemCount: leaderboardData.length,
                    itemBuilder: (context, index) {
                      final player   = leaderboardData[index];
                      final rank     = index + 1;
                      final playerId = _extractId(
                        player['player_id'] ?? player['id'] ?? player['_id'],
                      );
                      return _buildRankingRow(
                        player, rank, playerId == widget.currentUserId,
                      );
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

  // ── Tab pill button ──────────────────────────────────────────────────────────
  Widget _buildGameButton(String label, String gameId) {
    final isSelected = selectedGame == gameId;
    final color      = _getButtonColor(gameId);
    final isLight    = color.computeLuminance() > 0.5;
    final textColor  = isSelected
        ? (isLight ? Colors.black87 : Colors.white)
        : const Color(0xFF64748B);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          try { await AudioService().playClickSound(); } catch (_) {}
          setState(() {
            selectedGame       = gameId;
            leaderboardData    = [];
            selectedDifficulty = "EASY";
            selectedCategory   = "Solar System";
          });
          _loadLeaderboard();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13.5,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  // ── Filter dropdowns ─────────────────────────────────────────────────────────
  Widget _buildFilterDropdowns() {
    final color = _getCurrentGameColor();
    if (selectedGame == "badges" || selectedGame == "stars") {
      return const SizedBox.shrink();
    }
    if (selectedGame == "whiz_memory_match") {
      return _buildDropdown(
        value: selectedDifficulty,
        items: ["EASY", "AVERAGE", "DIFFICULT"],
        labels: ["Easy", "Average", "Difficult"],
        onChanged: (v) {
          if (v != null) { setState(() => selectedDifficulty = v); _loadLeaderboard(); }
        },
        color: color,
      );
    }
    if (selectedGame == "whiz_puzzle") {
      return Wrap(
        spacing: 8, runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildDropdown(
            value: selectedCategory,
            items: ["Solar System", "Scientists", "The Human Body",
              "Animals", "Geometry", "Starbooks"],
            onChanged: (v) {
              if (v != null) { setState(() => selectedCategory = v); _loadLeaderboard(); }
            },
            color: color, width: 150,
          ),
          _buildDropdown(
            value: selectedDifficulty,
            items: ["EASY", "AVERAGE", "DIFFICULT"],
            labels: ["Easy", "Average", "Difficult"],
            onChanged: (v) {
              if (v != null) { setState(() => selectedDifficulty = v); _loadLeaderboard(); }
            },
            color: color,
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    List<String>? labels,
    required void Function(String?) onChanged,
    required Color color,
    double width = 120,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        isDense: true,
        underline: const SizedBox(),
        icon: Icon(Icons.keyboard_arrow_down, size: 16, color: color),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        items: items.asMap().entries.map((e) {
          final label = labels != null ? labels[e.key] : e.value;
          return DropdownMenuItem(
            value: e.value,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // ── Table header ──────────────────────────────────────────────────────────────
  Widget _buildTableHeader() {
    final color   = _getCurrentGameColor();
    final isLight = color.computeLuminance() > 0.5;
    final textC   = isLight ? Colors.black87 : Colors.white;

    Widget col(String text, {int flex = 1, bool center = true}) => Expanded(
      flex: flex,
      child: center
          ? Center(
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: textC, fontWeight: FontWeight.w800,
                fontSize: 11, letterSpacing: 0.6)),
      )
          : Text(text,
          style: TextStyle(
              color: textC, fontWeight: FontWeight.w800,
              fontSize: 11, letterSpacing: 0.6)),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(width: 44,
              child: Center(child: Text("RANK",
                  style: TextStyle(color: textC, fontWeight: FontWeight.w800,
                      fontSize: 11, letterSpacing: 0.6)))),
          const SizedBox(width: 12),
          Expanded(flex: 3,
              child: Text("PLAYER",
                  style: TextStyle(color: textC, fontWeight: FontWeight.w800,
                      fontSize: 11, letterSpacing: 0.6))),
          if (selectedGame == "badges") ...[
            col("TOTAL\nBADGES"),
            col("EASY"),
            col("AVERAGE"),
            col("DIFFICULT"),
          ] else if (selectedGame == "stars") ...[
            col("STARS"),
            col("TIER", flex: 2),
          ] else ...[
            col("FASTEST TIME"),
            SizedBox(width: 80,
                child: Center(child: Text("MOVES",
                    style: TextStyle(color: textC, fontWeight: FontWeight.w800,
                        fontSize: 11, letterSpacing: 0.6)))),
          ],
        ],
      ),
    );
  }

  // ── Ranking row ───────────────────────────────────────────────────────────────
  Widget _buildRankingRow(Map<String, dynamic> player, int rank, bool isCurrentUser) {
    return StatefulBuilder(
      builder: (context, setRowState) {
        bool isHovered = false;
        return StatefulBuilder(
          builder: (context, setHover) {
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setHover(() => isHovered = true),
              onExit:  (_) => setHover(() => isHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? _gold.withValues(alpha: isHovered ? 0.14 : 0.08)
                      : isHovered
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCurrentUser
                        ? _gold.withValues(alpha: isHovered ? 0.6 : 0.45)
                        : isHovered
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFFE2E8F0),
                    width: isCurrentUser ? 1.5 : (isHovered ? 1.5 : 0.5),
                  ),
                  boxShadow: isHovered
                      ? [BoxShadow(
                      color: isCurrentUser
                          ? _gold.withValues(alpha: 0.12)
                          : const Color(0xFF3B82F6).withValues(alpha: 0.08),
                      blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  children: [
                    SizedBox(width: 44, child: _buildRankBadge(rank)),
                    const SizedBox(width: 12),
                    // ── Player ────────────────────────────────────────────────────────
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _getRankColor(rank), width: 2.5),
                              color: const Color(0xFFE2E8F0),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                player['avatar'] ?? "assets/images-avatars/Adventurer.png",
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person, color: Color(0xFF85B7EB), size: 22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player['username'] ?? player['player_username'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isCurrentUser ? _goldDark : const Color(0xFF1E293B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isCurrentUser)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: _gold,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text("YOU",
                                        style: TextStyle(
                                          fontSize: 9, fontWeight: FontWeight.w900,
                                          color: _navy, letterSpacing: 0.8,
                                        )),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Stats ─────────────────────────────────────────────────────────
                    if (selectedGame == "badges") ...[
                      Expanded(child: _stat(
                        "${(player['easy_count'] ?? 0) + (player['average_count'] ?? 0) + (player['difficult_count'] ?? 0)}",
                        const Color(0xFF1E293B), bold: true,
                      )),
                      Expanded(child: _stat("${player['easy_count']      ?? 0}", _easy)),
                      Expanded(child: _stat("${player['average_count']   ?? 0}", _average)),
                      Expanded(child: _stat("${player['difficult_count'] ?? 0}", _difficult)),

                    ] else if (selectedGame == "stars") ...[
                      Expanded(child: _stat("${player['stars'] ?? 0}", _gold, bold: true)),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _average.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _average.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              '${player['tier'] ?? ''}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700, color: _average),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),

                    ] else ...[
                      Expanded(child: _stat(_formatTime(player['time_seconds']), const Color(0xFF1E293B))),
                      SizedBox(
                        width: 80,
                        child: _stat("${player['moves'] ?? 0}", const Color(0xFF1E293B)),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RIGHT – User stats panel  (vertical scrollable layout)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildUserStatsPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 24, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Column(
        children: [
          _buildCompactUserProfile(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                children: [
                  _buildStarsSection(),
                  const SizedBox(height: 10),
                  _buildBadgesSection(),
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildMemoryMatchCard()),
                        const SizedBox(width: 10),
                        Expanded(child: _buildPuzzleCard()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactUserProfile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _blue,
              border: Border.all(color: _gold, width: 2.5),
            ),
            child: ClipOval(
              child: Image.asset(
                widget.userAvatar,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.person, size: 28, color: Color(0xFF85B7EB)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.username,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _gold.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'Your Stats',
                    style: TextStyle(fontSize: 10, color: _gold, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stars section ─────────────────────────────────────────────────────────────
  Widget _buildStarsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _average.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _average.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('STARS', style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8), letterSpacing: 0.8)),
                const SizedBox(height: 2),
                Text('$_playerStars', style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), height: 1)),
              ],
            ),
          ),
          // Tier badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _average.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _average.withValues(alpha: 0.5)),
            ),
            child: Text(
              _playerTier,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: _average),
            ),
          ),
        ],
      ),
    );
  }

  // ── Badges section – shows all 3 difficulty counts ────────────────────────────
  Widget _buildBadgesSection() {
    final easy      = _badgeCounts['easy_count']      ?? 0;
    final average   = _badgeCounts['average_count']   ?? 0;
    final difficult = _badgeCounts['difficult_count'] ?? 0;
    final total     = easy + average + difficult;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.military_tech_rounded, color: _gold, size: 22),
                ),
                const SizedBox(width: 10),
                const Text('BADGES', style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8), letterSpacing: 0.8)),
                const Spacer(),
                Text('$total total', style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: _gold)),
              ],
            ),
          ),
          // Divider
          Divider(height: 1, color: const Color(0xFFE2E8F0)),
          // Three difficulty counts
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                _badgeDiffTile('Easy',     '$easy',     _easy,      'assets/images-badges/whiz-ready.png'),
                _badgeDiffTile('Average',  '$average',  _average,   'assets/images-badges/whiz-happy.png'),
                _badgeDiffTile('Difficult','$difficult', _difficult, 'assets/images-badges/whiz-achiever.png'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeDiffTile(String label, String count, Color color, String imagePath) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(imagePath, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(Icons.military_tech_rounded, color: color, size: 24)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(count, style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  // ── Memory Match card ─────────────────────────────────────────────────────────
  Widget _buildMemoryMatchCard() {
    const accentColor = _purple;
    final diff    = _gameDifficultiesDisplay[_currentMemoryDifficultyIndex];
    final timeStr = _formatTime(_memoryMatchStats?['time_seconds']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title row — centered
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.grid_view_rounded, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Flexible(
                child: Text('MEMORY MATCH', style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8), letterSpacing: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Time centered
          Text(timeStr, style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), height: 1),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          const Text('fastest time', style: TextStyle(
              fontSize: 11, color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          // Difficulty picker right below time
          Center(
            child: _difficultyPicker(
              diff: diff, accentColor: accentColor,
              onLeft: () {
                setState(() {
                  _currentMemoryDifficultyIndex =
                      (_currentMemoryDifficultyIndex - 1 + _gameDifficulties.length) % _gameDifficulties.length;
                  _memoryMatchStats = null;
                });
                _fetchMemoryMatchStat();
              },
              onRight: () {
                setState(() {
                  _currentMemoryDifficultyIndex =
                      (_currentMemoryDifficultyIndex + 1) % _gameDifficulties.length;
                  _memoryMatchStats = null;
                });
                _fetchMemoryMatchStat();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Puzzle card ───────────────────────────────────────────────────────────────
  Widget _buildPuzzleCard() {
    const accentColor = _orange;
    final diff    = _gameDifficultiesDisplay[_currentPuzzleDifficultyIndex];
    final timeStr = _formatTime(_puzzleStats?['time_seconds']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.extension_rounded, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('PUZZLE', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8), letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 14),
          // Time centered
          Text(timeStr, style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), height: 1),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          const Text('fastest time', style: TextStyle(
              fontSize: 11, color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          // Category chips centered
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 5, runSpacing: 5,
            children: List.generate(_puzzleCategories.length, (i) {
              final isSelected = i == _currentPuzzleCategoryIndex;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    setState(() { _currentPuzzleCategoryIndex = i; _puzzleStats = null; });
                    _fetchPuzzleStat();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isSelected ? accentColor : const Color(0xFFCBD5E1)),
                    ),
                    child: Text(_puzzleCategoriesShort[i],
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : const Color(0xFF64748B))),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Difficulty picker centered at bottom
          Center(
            child: _difficultyPicker(
              diff: diff, accentColor: accentColor,
              onLeft: () {
                setState(() {
                  _currentPuzzleDifficultyIndex =
                      (_currentPuzzleDifficultyIndex - 1 + _gameDifficulties.length) % _gameDifficulties.length;
                  _puzzleStats = null;
                });
                _fetchPuzzleStat();
              },
              onRight: () {
                setState(() {
                  _currentPuzzleDifficultyIndex =
                      (_currentPuzzleDifficultyIndex + 1) % _gameDifficulties.length;
                  _puzzleStats = null;
                });
                _fetchPuzzleStat();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Shared small helpers
  // ═══════════════════════════════════════════════════════════════════════════



  /// Left / right chevron button used inside side cards.
  Widget _arrowBtn(IconData icon, VoidCallback onTap, Color color) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 20, height: 20,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
          child: Icon(icon, size: 15, color: Colors.white),
        ),
      ),
    );
  }

  /// Prev / next difficulty pill for Memory & Puzzle cards.
  Widget _difficultyPicker({
    required String diff,
    required Color accentColor,
    required VoidCallback onLeft,
    required VoidCallback onRight,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onLeft,
              child: Container(
                width: 22, height: 20, color: accentColor,
                child: const Icon(Icons.chevron_left, size: 14, color: Colors.white),
              ),
            ),
          ),
          Container(
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: accentColor.withValues(alpha: 0.18),
            child: Center(
              child: Text(diff,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accentColor)),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onRight,
              child: Container(
                width: 22, height: 20, color: accentColor,
                child: const Icon(Icons.chevron_right, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, Color color, {bool bold = false}) {
    return Center(
      child: Text(
        value,
        style: TextStyle(
          fontSize: bold ? 17 : 15,
          fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    final bg = _getRankColor(rank);

    if (rank <= 3) {
      final medals = ['🥇', '🥈', '🥉'];
      return Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.20),
          shape: BoxShape.circle,
          border: Border.all(color: bg, width: 2),
        ),
        child: Center(
          child: Text(medals[rank - 1], style: const TextStyle(fontSize: 20)),
        ),
      );
    }

    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text('$rank',
            style: const TextStyle(
                color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 14)),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:  return const Color(0xFFFFD700);
      case 2:  return const Color(0xFFC0C0C0);
      case 3:  return const Color(0xFFCD7F32);
      default: return const Color(0xFFCBD5E1);
    }
  }
}