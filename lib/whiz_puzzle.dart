import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WhizPuzzle extends StatefulWidget {
  final String userAvatar;
  final String playerId;

  const WhizPuzzle({
    super.key,
    this.userAvatar = "assets/images-avatars/Adventurer.png",
    required this.playerId,
  });

  @override
  State<WhizPuzzle> createState() => _WhizPuzzleState();
}

class _WhizPuzzleState extends State<WhizPuzzle> {
  String _difficulty = "EASY";
  String? _category;
  bool _gameStarted = false;
  int _moves = 0;
  int _timer = 0;
  bool _isPaused = false;
  bool _isCompleted = false;

  int? _globalFastestTime;
  int? _globalFastestMoves;
  final String baseUrl = "http://127.0.0.1:8000";
  int? _fastestTime;
  Timer? _gameTimer;

  late int _gridSize;

  Color _getDifficultyBorderColor() {
    switch (_difficulty) {
      case "EASY":
        return const Color(0xFF2E7D32);
      case "AVERAGE":
        return const Color(0xFF1976D2);
      case "DIFFICULT":
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  List<PuzzlePiece> _pieces = [];
  String? _imageUrl;

  final List<String> _categories = [
    'Solar System',
    'Scientists',
    'The Human Body',
    'Animals',
    'Geometry',
    'Starbooks',
  ];

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    if (_category == null) {
      _showWarningDialog();
      return;
    }

    setState(() {
      _gameStarted = true;
      _moves = 0;
      _timer = 0;
      _isPaused = false;
      _isCompleted = false;
      _initializePuzzle();
    });

    // Add this line:
    _loadFastestTime();

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isPaused && !_isCompleted) {
        setState(() => _timer++);
      }
    });
  }

// Add _loadFastestTime method:
  Future<void> _loadFastestTime() async {
    try {
      // Load personal fastest time
      String url = '$baseUrl/api/game/fastest-time/${widget.playerId}/puzzle/$_difficulty';

      if (_category != null) {
        url += '?category=$_category';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          setState(() {
            _fastestTime = data['data']['time_seconds'];
          });
        }
      }

      // Load global fastest time
      await _loadGlobalFastestTime();
    } catch (e) {
      debugPrint('Error loading fastest times: $e');
    }
  }

  void _initializePuzzle() {
    switch (_difficulty) {
      case "EASY":
        _gridSize = 3;
        break;
      case "AVERAGE":
        _gridSize = 4;
        break;
      case "DIFFICULT":
        _gridSize = 5;
        break;
      default:
        _gridSize = 3;
    }

    _imageUrl = _getCategoryImage(_category!);

    List<PuzzlePiece> pieces = [];
    final random = Random();
    final trayWidth = 260.0;
    final trayHeight = 400.0;

    for (int i = 0; i < _gridSize * _gridSize; i++) {
      final correctRow = i ~/ _gridSize;
      final correctCol = i % _gridSize;

      pieces.add(PuzzlePiece(
        id: i,
        correctRow: correctRow,
        correctCol: correctCol,
        trayX: random.nextDouble() * (trayWidth - 60),
        trayY: random.nextDouble() * (trayHeight - 60),
        isLocked: false,
        isInTray: true,
      ));
    }

    _pieces = pieces;
  }

  String _getCategoryImage(String category) {
    switch (category) {
      case 'Solar System':
        return 'assets/puzzle/solar_system.png';
      case 'Scientists':
        return 'assets/puzzle/scientists.jpg';
      case 'The Human Body':
        return 'assets/puzzle/human_body.png';
      case 'Animals':
        return 'assets/puzzle/animals.jpg';
      case 'Geometry':
        return 'assets/puzzle/geometry.jpg';
      case 'Starbooks':
        return 'assets/puzzle/starbookswhiz.jpeg';
      default:
        return 'assets/puzzle/animals.png';
    }
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  // Update _checkCompletion to also load global fastest time
  Future<void> _checkCompletion() async {
    if (_pieces.every((piece) => piece.isLocked)) {
      setState(() {
        _isCompleted = true;
        _gameTimer?.cancel();
        if (_fastestTime == null || _timer < _fastestTime!) {
          _fastestTime = _timer;
        }
      });

      // Save the time first
      await _saveFastestTime();

      // Load global time
      await _loadGlobalFastestTime();

      // Then show dialog
      if (mounted) {
        _showCompletionDialog();
      }
    }
  }

  Future<void> _saveFastestTime() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/game/fastest-time'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'player_id': widget.playerId,
          'game_type': 'puzzle',
          'difficulty': _difficulty,
          'category': _category,
          'time_seconds': _timer,
          'moves': _moves,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['is_new_record']) {
          await _loadGlobalFastestTime();
        }
      }
    } catch (e) {
      debugPrint('Error saving fastest time: $e');
    }
  }

  void _showWarningDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, size: 60, color: Color(0xFF656BE6)),
              const SizedBox(height: 15),
              const Text(
                "Incomplete Selection",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please select a category before starting the game.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF656BE6),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("OK", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPauseDialog() {
    setState(() => _isPaused = true);
    _gameTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  const Text(
                    "PAUSED!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE6833A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24, color: Colors.black54),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _isPaused = false);
                      _resumeGame();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _isPaused = false);
                    _resumeGame();
                  },
                  icon: const Icon(Icons.play_arrow, size: 22),
                  label: const Text(
                    "RESUME",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE6833A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.home, size: 22),
                  label: const Text(
                    "EXIT",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black54,
                    side: const BorderSide(color: Colors.black26, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resumeGame() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isPaused && !_isCompleted) {
        setState(() => _timer++);
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6833A).withValues(alpha:0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 60,
                  color: Color(0xFFE6833A),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "FANTASTIC!",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE6833A),
                ),
              ),
              const SizedBox(height: 20),
              _PuzzleWinStatsAnimation(
                timeSeconds: _timer,
                moves: _moves,
                fastestTime: _fastestTime,
                globalFastestTime: _globalFastestTime,
                globalFastestMoves: _globalFastestMoves,
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE6833A),
                        side: const BorderSide(color: Color(0xFFE6833A), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text(
                        "EXIT",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _startGame();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE6833A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: const Text(
                        "PLAY AGAIN",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Future<void> _loadGlobalFastestTime() async {
    try {
      String url = '$baseUrl/api/game/fastest-times/leaderboard?game_type=puzzle&difficulty=$_difficulty';

      if (_category != null) {
        url += '&category=$_category';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> times = data['data'] ?? [];
          if (times.isNotEmpty) {
            setState(() {
              _globalFastestTime = times[0]['time_seconds'];
              _globalFastestMoves = times[0]['moves'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading global fastest time: $e');
    }
  }

  Future<void> _logoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset("assets/images-icons/sadlogout.png", width: 80, height: 80),
              const SizedBox(height: 15),
              const Text("Logout Confirmation",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              const Text("Are you sure you want to log out?",
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF046EB8), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Cancel",
                          style: TextStyle(fontSize: 14, color: Color(0xFF046EB8))),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDD000),
                        foregroundColor: const Color(0xFF816A03),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Logout",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          if (!_gameStarted) _buildTopBar(),
          Expanded(
            child: _gameStarted ? _buildGameBoard() : _buildDifficultySelection(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 28),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Image.asset("assets/images-logo/mainlogo.png",
                  width: 150, height: 50, fit: BoxFit.contain),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTopNavButton("Home", Icons.home, () {
                        Navigator.pop(context);
                      }),
                      const SizedBox(width: 40),
                      _buildTopNavButton("Leaderboard", Icons.leaderboard, () {}),
                    ],
                  ),
                ),
              ),
              // User avatar with logout functionality
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _logoutDialog,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF046EB8), width: 3),
                    ),
                    child: ClipOval(
                      child: Image.asset(widget.userAvatar, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFFE6833A),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 2))
            ],
          ),
          child: const Text(
            "Whiz Puzzle",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopNavButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.grey[700], size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Container(height: 3, width: 0, color: Colors.transparent),
        ],
      ),
    );
  }

  Widget _buildDifficultySelection() {
    return Container(
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Difficulty Level",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE6833A),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Column(
                          children: [
                            _buildDifficultyButton("EASY", "3x3 Grid", const Color(0xFF2E7D32)),
                            const SizedBox(height: 16),
                            _buildDifficultyButton("AVERAGE", "4x4 Grid", const Color(0xFF1976D2)),
                            const SizedBox(height: 16),
                            _buildDifficultyButton("DIFFICULT", "5x5 Grid", const Color(0xFFD32F2F)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 80),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Select Category",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE6833A),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: 700,
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 2.8,
                            ),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = _category == category;

                              Color categoryColor = const Color(0xFF9E9E9E);
                              if (isSelected) {
                                categoryColor = _getDifficultyBorderColor();
                              }

                              return GestureDetector(
                                onTap: () => setState(() => _category = category),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  decoration: BoxDecoration(
                                    color: isSelected ? categoryColor : Colors.white,
                                    border: Border.all(
                                      color: isSelected ? categoryColor : const Color(0xFF9E9E9E),
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE6833A),
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 4,
                ),
                child: const Text(
                  "Start Game",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(String level, String gridInfo, Color color) {
    bool isSelected = _difficulty == level;
    return GestureDetector(
      onTap: () => setState(() => _difficulty = level),
      child: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          children: [
            Text(
              level,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              gridInfo,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white.withValues(alpha:0.9) : color.withValues(alpha:0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameBoard() {
    final gridCellSize = _difficulty == "EASY" ? 165.0 : (_difficulty == "AVERAGE" ? 125.0 : 105.0);

    return Container(
      color: const Color(0xFFE6833A),
      child: Stack(
        children: [
          Column(
            children: [
              _buildGameStats(),
              const SizedBox(height: 55),
              Text(
                _category ?? "",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: gridCellSize * _gridSize,
                      height: gridCellSize * _gridSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.3),
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _gridSize,
                        ),
                        itemCount: _gridSize * _gridSize,
                        itemBuilder: (context, index) {
                          final row = index ~/ _gridSize;
                          final col = index % _gridSize;
                          final piece = _pieces.firstWhere(
                                (p) => p.isLocked && p.correctRow == row && p.correctCol == col,
                            orElse: () => PuzzlePiece(
                              id: -1,
                              correctRow: -1,
                              correctCol: -1,
                              trayX: 0,
                              trayY: 0,
                              isLocked: false,
                            ),
                          );

                          return DragTarget<int>(
                            onWillAcceptWithDetails: (details) => !_isPaused,
                            onAcceptWithDetails: (details) {
                              final draggedPiece = _pieces.firstWhere((p) => p.id == details.data);
                              setState(() {
                                if (draggedPiece.correctRow == row && draggedPiece.correctCol == col) {
                                  draggedPiece.isLocked = true;
                                  _checkCompletion();
                                }
                                _moves++;
                              });
                            },
                            builder: (context, candidateData, rejectedData) {
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white, width: 2),
                                  color: piece.id != -1
                                      ? Colors.white.withValues(alpha:0.2)
                                      : Colors.transparent,
                                ),
                                child: piece.id != -1
                                    ? _buildPuzzlePieceImage(piece, gridCellSize)
                                    : const SizedBox.shrink(),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 40),
                    Container(
                      width: 280,
                      height: gridCellSize * _gridSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: _pieces
                            .where((piece) => !piece.isLocked && piece.isInTray)
                            .map((piece) => _buildDraggablePiece(piece, gridCellSize))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
          ..._pieces
              .where((piece) => !piece.isLocked && !piece.isInTray && piece.floatingPosition != null)
              .map((piece) => _buildFloatingPiece(piece, gridCellSize))
        ],
      ),
    );
  }

  Widget _buildDraggablePiece(PuzzlePiece piece, double cellSize) {
    return Positioned(
      left: piece.trayX,
      top: piece.trayY,
      child: Draggable<int>(
        data: piece.id,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.8,
            child: _buildPuzzlePieceImage(piece, cellSize * 0.8),
          ),
        ),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          if (!piece.isLocked) {
            setState(() {
              piece.isInTray = false;
              piece.floatingPosition = details.offset;
            });
          }
        },
        child: _buildPuzzlePieceImage(piece, cellSize * 0.8),
      ),
    );
  }

  Widget _buildPuzzlePieceImage(PuzzlePiece piece, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.none,
          alignment: Alignment(
            _gridSize == 1 ? 0.0 : (piece.correctCol / (_gridSize - 1)) * 2 - 1,
            _gridSize == 1 ? 0.0 : (piece.correctRow / (_gridSize - 1)) * 2 - 1,
          ),
          child: SizedBox(
            width: size * _gridSize,
            height: size * _gridSize,
            child: Image.asset(
              _imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey,
                  child: Center(
                    child: Icon(
                      Icons.image,
                      size: size * 0.5,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingPiece(PuzzlePiece piece, double cellSize) {
    return Positioned(
      left: piece.floatingPosition!.dx,
      top: piece.floatingPosition!.dy,
      child: Draggable<int>(
        data: piece.id,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.8,
            child: _buildPuzzlePieceImage(piece, cellSize * 0.8),
          ),
        ),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          if (!piece.isLocked) {
            setState(() {
              piece.floatingPosition = details.offset;
            });
          }
        },
        child: _buildPuzzlePieceImage(piece, cellSize * 0.8),
      ),
    );
  }

  Widget _buildGameStats() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Moves: $_moves",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE6833A),
                    ),
                  ),
                ),
              ),
              Expanded(child: Container()),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.pause_circle, size: 44, color: Color(0xFFE6833A)),
                  onPressed: _showPauseDialog,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 50,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE6833A),
              border: Border.all(
                color: Colors.white,
                width: 5,
              ),
            ),
            child: Center(
              child: Text(
                _formatTime(_timer),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// PuzzlePiece class
class PuzzlePiece {
  final int id;
  final int correctRow;
  final int correctCol;
  double trayX;
  double trayY;
  bool isLocked;
  bool isInTray;
  Offset? floatingPosition;

  PuzzlePiece({
    required this.id,
    required this.correctRow,
    required this.correctCol,
    required this.trayX,
    required this.trayY,
    required this.isLocked,
    this.isInTray = true,
    this.floatingPosition,
  });
}

// Animation widget for completion stats
class _PuzzleWinStatsAnimation extends StatefulWidget {
  final int timeSeconds;
  final int moves;
  final int? fastestTime;
  final int? globalFastestTime;
  final int? globalFastestMoves;

  const _PuzzleWinStatsAnimation({
    required this.timeSeconds,
    required this.moves,
    this.fastestTime,
    this.globalFastestTime,
    this.globalFastestMoves,
  });

  @override
  State<_PuzzleWinStatsAnimation> createState() => _PuzzleWinStatsAnimationState();
}

class _PuzzleWinStatsAnimationState extends State<_PuzzleWinStatsAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _timeController;
  late final AnimationController _fastestTimeController;
  late final AnimationController _globalFastestTimeController;
  late final AnimationController _timePopController;
  late final AnimationController _fastestTimePopController;
  late final AnimationController _globalFastestTimePopController;

  @override
  void initState() {
    super.initState();

    _timeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fastestTimeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _globalFastestTimeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _timePopController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fastestTimePopController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _globalFastestTimePopController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Check if player just set a new personal record
    final bool isNewPersonalRecord = widget.fastestTime == null ||
        widget.timeSeconds <= widget.fastestTime!;

    // Check if player just set a new global record
    final bool isNewGlobalRecord = widget.globalFastestTime == null ||
        widget.timeSeconds < widget.globalFastestTime!;

    // 1. Count up time
    await _timeController.forward();
    await _timePopController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _timePopController.reverse();

    // 2. Show personal fastest time (only if NOT a new record)
    if (!isNewPersonalRecord && widget.fastestTime != null) {
      await _fastestTimeController.forward();
      await _fastestTimePopController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _fastestTimePopController.reverse();
    }

    // 3. Count up global fastest time (only if player beat it)
    if (isNewGlobalRecord && widget.globalFastestTime != null) {
      await _globalFastestTimeController.forward();
      await _globalFastestTimePopController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _globalFastestTimePopController.reverse();
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    _fastestTimeController.dispose();
    _globalFastestTimeController.dispose();
    _timePopController.dispose();
    _fastestTimePopController.dispose();
    _globalFastestTimePopController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  List<Widget> _buildRainbowGlow(double glowIntensity) {
    return [
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: glowIntensity * 0.4),
                blurRadius: 30 * glowIntensity,
                spreadRadius: 8 * glowIntensity,
              ),
            ],
          ),
        ),
      ),
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: glowIntensity * 0.4),
                blurRadius: 26 * glowIntensity,
                spreadRadius: 6 * glowIntensity,
              ),
            ],
          ),
        ),
      ),
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withValues(alpha: glowIntensity * 0.4),
                blurRadius: 22 * glowIntensity,
                spreadRadius: 5 * glowIntensity,
              ),
            ],
          ),
        ),
      ),
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: glowIntensity * 0.4),
                blurRadius: 18 * glowIntensity,
                spreadRadius: 4 * glowIntensity,
              ),
            ],
          ),
        ),
      ),
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: glowIntensity * 0.4),
                blurRadius: 14 * glowIntensity,
                spreadRadius: 3 * glowIntensity,
              ),
            ],
          ),
        ),
      ),
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: glowIntensity * 0.4),
                blurRadius: 10 * glowIntensity,
                spreadRadius: 2 * glowIntensity,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Check if player just set a new personal record
    final bool isNewPersonalRecord = widget.fastestTime == null ||
        widget.timeSeconds <= widget.fastestTime!;

    // Check if player just set a new global record
    final bool isNewGlobalRecord = widget.globalFastestTime == null ||
        widget.timeSeconds < widget.globalFastestTime!;

    return Column(
      children: [
        // Time Played Row
        AnimatedBuilder(
          animation: Listenable.merge([_timeController, _timePopController]),
          builder: (context, child) {
            final currentSeconds = (_timeController.value * widget.timeSeconds).round();
            final scale = 1.0 + (_timePopController.value * 0.2);
            final glowIntensity = _timePopController.value;

            return Transform.scale(
              scale: scale,
              child: Column(
                children: [
                  Text(
                    isNewPersonalRecord ? "🎉 NEW PERSONAL RECORD!" : "Your Time:",
                    style: TextStyle(
                      fontSize: 16,
                      color: isNewPersonalRecord ? const Color(0xFFE6833A) : Colors.black54,
                      fontWeight: isNewPersonalRecord ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      if (glowIntensity > 0) ..._buildRainbowGlow(glowIntensity),
                      Text(
                        _formatTime(currentSeconds),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Personal Fastest Time Row (only show if NOT a new record)
        if (!isNewPersonalRecord && widget.fastestTime != null)
          AnimatedBuilder(
            animation: Listenable.merge([_fastestTimeController, _fastestTimePopController]),
            builder: (context, child) {
              final currentSeconds = (_fastestTimeController.value * widget.fastestTime!).round();
              final scale = 1.0 + (_fastestTimePopController.value * 0.2);
              final glowIntensity = _fastestTimePopController.value;

              return Transform.scale(
                scale: scale,
                child: Column(
                  children: [
                    const Text(
                      "Your Previous Best:",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        if (glowIntensity > 0) ..._buildRainbowGlow(glowIntensity),
                        Text(
                          _formatTime(currentSeconds),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

        // Global Fastest Time Row (only show with animation if player beat it)
        if (isNewGlobalRecord && widget.globalFastestTime != null) ...[
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: Listenable.merge([_globalFastestTimeController, _globalFastestTimePopController]),
            builder: (context, child) {
              final currentSeconds = (_globalFastestTimeController.value * widget.globalFastestTime!).round();
              final scale = 1.0 + (_globalFastestTimePopController.value * 0.2);
              final glowIntensity = _globalFastestTimePopController.value;

              return Transform.scale(
                scale: scale,
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events, color: Color(0xFFFDD000), size: 20),
                        const SizedBox(width: 6),
                        const Text(
                          "Previous Global Record:",
                          style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        if (glowIntensity > 0) ..._buildRainbowGlow(glowIntensity),
                        Text(
                          _formatTime(currentSeconds),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFDD000),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "🏆 YOU BEAT THE GLOBAL RECORD! 🏆",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFFDD000),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ] else if (!isNewGlobalRecord && widget.globalFastestTime != null) ...[
          // Show global record without animation if player didn't beat it
          const SizedBox(height: 12),
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, color: Color(0xFFFDD000), size: 20),
                  const SizedBox(width: 6),
                  const Text(
                    "Global Record:",
                    style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _formatTime(widget.globalFastestTime!),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFDD000),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}