import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class WhizPuzzle extends StatefulWidget {
  final String userAvatar;

  const WhizPuzzle({
    super.key,
    this.userAvatar = "assets/images-avatars/Adventurer.png",
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
  int? _fastestTime;
  Timer? _gameTimer;
  bool _isPaused = false;
  bool _isCompleted = false;

  late int _gridSize;
  late Color _difficultyColor;
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

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isPaused && !_isCompleted) {
        setState(() => _timer++);
      }
    });
  }

  void _initializePuzzle() {
    switch (_difficulty) {
      case "EASY":
        _gridSize = 3;
        _difficultyColor = const Color(0xFF2E7D32);
        break;
      case "AVERAGE":
        _gridSize = 4;
        _difficultyColor = const Color(0xFF1976D2);
        break;
      case "DIFFICULT":
        _gridSize = 5;
        _difficultyColor = const Color(0xFFD32F2F);
        break;
      default:
        _gridSize = 3;
        _difficultyColor = const Color(0xFF2E7D32);
    }

    _imageUrl = _getCategoryImage(_category!);

    List<PuzzlePiece> pieces = [];
    final random = Random();
    final trayWidth = 260.0;
    final trayHeight = 560.0;

    for (int i = 0; i < _gridSize * _gridSize; i++) {
      final correctRow = i ~/ _gridSize;
      final correctCol = i % _gridSize;

      pieces.add(PuzzlePiece(
        id: i,
        correctRow: correctRow,
        correctCol: correctCol,
        trayX: random.nextDouble() * (trayWidth - 80),
        trayY: random.nextDouble() * (trayHeight - 80),
        isLocked: false,
      ));
    }

    _pieces = pieces;
  }

  String _getCategoryImage(String category) {
    switch (category) {
      case 'Solar System':
        return 'assets/puzzle/solar_system.png';
      case 'Scientists':
        return 'assets/puzzle/scientists.png';
      case 'The Human Body':
        return 'assets/puzzle/human_body.png';
      case 'Animals':
        return 'assets/puzzle/animals.png';
      case 'Geometry':
        return 'assets/puzzle/geometry.png';
      case 'Starbooks':
        return 'assets/puzzle/starbooks.png';
      default:
        return 'assets/puzzle/animals.png';
    }
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  void _checkCompletion() {
    if (_pieces.every((piece) => piece.isLocked)) {
      setState(() {
        _isCompleted = true;
        _gameTimer?.cancel();
        if (_fastestTime == null || _timer < _fastestTime!) {
          _fastestTime = _timer;
        }
      });
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(30),
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
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5F6FDB),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _isPaused = false);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _isPaused = false);
                },
                icon: const Icon(Icons.play_arrow, size: 24),
                label: const Text(
                  "Resume",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF046EB8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.home, size: 24),
                label: const Text(
                  "Exit",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDD000),
                  foregroundColor: const Color(0xFF915701),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 80, color: Color(0xFFFDD000)),
              const SizedBox(height: 20),
              const Text(
                "Congratulations!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Text("Time: ${_formatTime(_timer)}", style: const TextStyle(fontSize: 18)),
              Text("Moves: $_moves", style: const TextStyle(fontSize: 18)),
              Text("Fastest Time: ${_formatTime(_fastestTime ?? _timer)}",
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _startGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF046EB8),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: const Text("Play Again", style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD000),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: const Text("Exit", style: TextStyle(color: Color(0xFF915701))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 10),
              Image.asset("assets/images-logo/mainlogo.png", width: 150, height: 50, fit: BoxFit.contain),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.home, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.leaderboard, color: Colors.black),
                onPressed: () {},
              ),
              const SizedBox(width: 10),
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
          color: const Color(0xFF656BE6),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: const Text(
            "Whiz Puzzle",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySelection() {
    return Container(
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Difficulty Level",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5F6FDB),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDifficultyButton("EASY", "3x3 Grid", const Color(0xFF2E7D32)),
                  const SizedBox(width: 20),
                  _buildDifficultyButton("AVERAGE", "4x4 Grid", const Color(0xFF1976D2)),
                  const SizedBox(width: 20),
                  _buildDifficultyButton("DIFFICULT", "5x5 Grid", const Color(0xFFD32F2F)),
                ],
              ),
              const SizedBox(height: 60),
              const Text(
                "Select Category",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5F6FDB),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 900,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _category == category;
                    return GestureDetector(
                      onTap: () => setState(() => _category = category),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF9E9E9E) : Colors.white,
                          border: Border.all(color: const Color(0xFF9E9E9E), width: 3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 18,
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
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDD000),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  "Start Game",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF915701),
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
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 25),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          children: [
            Text(
              level,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              gridInfo,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white.withOpacity(0.9) : color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameBoard() {
    if (_isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCompletionDialog();
      });
    }

    return Container(
      color: _difficultyColor,
      child: Column(
        children: [
          _buildGameStats(),
          const SizedBox(height: 80),
          Expanded(
            child: Center(
              child: Text(
                _category ?? "",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Text(
            "Puzzle game board would render here",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 40),
        ],
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _difficultyColor,
                    ),
                  ),
                ),
              ),
              Expanded(child: Container()),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.pause_circle, size: 40, color: _difficultyColor),
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
              color: _difficultyColor,
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

class PuzzlePiece {
  final int id;
  final int correctRow;
  final int correctCol;
  double trayX;
  double trayY;
  bool isLocked;

  PuzzlePiece({
    required this.id,
    required this.correctRow,
    required this.correctCol,
    required this.trayX,
    required this.trayY,
    required this.isLocked,
  });
}