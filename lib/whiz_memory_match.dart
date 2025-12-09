import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'leaderboard.dart';

class WhizMemoryMatch extends StatefulWidget {
  final String userAvatar;
  final String playerId;

  const WhizMemoryMatch({
    super.key,
    this.userAvatar = "assets/images-avatars/Adventurer.png",
    required this.playerId,
  });

  @override
  State<WhizMemoryMatch> createState() => _WhizMemoryMatchState();
}


class _WhizMemoryMatchState extends State<WhizMemoryMatch>
    with TickerProviderStateMixin {
  String _difficulty = "EASY";
  bool _gameStarted = false;
  int _moves = 0;
  int _score = 0;
  int _timer = 0;
  Timer? _gameTimer;

  int? _globalFastestTime;
  int? _globalFastestMoves;
  int? _fastestTime;
  int? _fastestMoves;
  final String baseUrl = "http://127.0.0.1:8000";

  List<CardItem> _cards = [];
  List<int> _flippedIndices = [];
  bool _isChecking = false;

  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _moves = 0;
      _score = 0;
      _timer = 0;
      _generateCards();
    });

    _loadFastestTime();

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _timer++);
      }
    });
  }

  Future<void> _saveFastestTime() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/game/fastest-time'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'player_id': widget.playerId,
          'game_type': 'memory_match',
          'difficulty': _difficulty,
          'time_seconds': _timer,
          'moves': _moves,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['is_new_record']) {
          await _loadFastestTime();
        }
      }
    } catch (e) {
      //
    }
  }

  Future<void> _loadFastestTime() async {
    try {
      // Load personal fastest time
      final response = await http.get(
        Uri.parse('$baseUrl/api/game/fastest-time/${widget.playerId}/memory_match/$_difficulty'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          setState(() {
            _fastestTime = data['data']['time_seconds'];
            _fastestMoves = data['data']['moves'];
          });
        }
      }

      // Load global fastest time (leaderboard top entry)
      final leaderboardResponse = await http.get(
        Uri.parse('$baseUrl/api/game/fastest-times/leaderboard?game_type=memory_match&difficulty=$_difficulty'),
      );

      if (leaderboardResponse.statusCode == 200) {
        final leaderboardData = json.decode(leaderboardResponse.body);
        if (leaderboardData['success'] == true) {
          final List<dynamic> times = leaderboardData['data'] ?? [];
          if (times.isNotEmpty) {
            setState(() {
              _globalFastestTime = times[0]['time_seconds'];
              _globalFastestMoves = times[0]['moves'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading fastest times: $e');
    }
  }

  void _generateCards() {
    final pairs = _difficulty == "EASY" ? 5 : (_difficulty == "AVERAGE" ? 6 : 7);
    final prefix = _difficulty.toLowerCase();

    final cards = <CardItem>[];
    for (int i = 1; i <= pairs; i++) {
      final image = "assets/memorymatch/$prefix$i.png";
      cards.add(CardItem(id: i, imagePath: image));
      cards.add(CardItem(id: i, imagePath: image));
    }
    cards.shuffle(Random());
    setState(() {
      _cards = cards;
      _flippedIndices = [];
      _isChecking = false;
    });
  }

  void _onCardTap(int index) {
    if (_isChecking ||
        _cards[index].isMatched ||
        _cards[index].isFlipped ||
        _flippedIndices.length >= 2) {
      return;
    }

    setState(() {
      _cards[index].isFlipped = true;
      _flippedIndices.add(index);
    });

    if (_flippedIndices.length == 2) {
      _moves++;
      _checkMatch();
    }
  }

  Future<void> _checkMatch() async {
    _isChecking = true;
    final int firstIndex = _flippedIndices[0];
    final int secondIndex = _flippedIndices[1];

    final bool isMatch = _cards[firstIndex].id == _cards[secondIndex].id;

    setState(() {
      _cards[firstIndex].isMatching = isMatch;
      _cards[secondIndex].isMatching = isMatch;
      _cards[firstIndex].isNotMatching = !isMatch;
      _cards[secondIndex].isNotMatching = !isMatch;
    });

    await Future.delayed(const Duration(milliseconds: 700));

    setState(() {
      if (isMatch) {
        _cards[firstIndex].isMatched = true;
        _cards[secondIndex].isMatched = true;
        final points = _difficulty == "EASY" ? 5 : (_difficulty == "AVERAGE" ? 6 : 7);
        _score += points;
      } else {
        _cards[firstIndex].isFlipped = false;
        _cards[secondIndex].isFlipped = false;
      }

      _cards[firstIndex].isMatching = false;
      _cards[secondIndex].isMatching = false;
      _cards[firstIndex].isNotMatching = false;
      _cards[secondIndex].isNotMatching = false;

      _flippedIndices.clear();
      _isChecking = false;
    });

    _checkWin();
  }

  void _checkWin() {
    if (_cards.isNotEmpty && _cards.every((card) => card.isMatched)) {
      _gameTimer?.cancel();
      _saveFastestTime();
      _showWinDialog();
    }
  }

  void _showWinDialog() {
    _confettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Confetti animation
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(10, (index) {
                    return ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirection: pi / 2,
                      emissionFrequency: 0.05,
                      numberOfParticles: 10,
                      maxBlastForce: 15,
                      minBlastForce: 8,
                      gravity: 0.3,
                      colors: const [
                        Color(0xFFFDD000),
                        Color(0xFF5F6FDB),
                        Color(0xFF046EB8),
                        Colors.red,
                        Colors.green,
                        Colors.orange,
                        Colors.pink,
                        Colors.purple,
                      ],
                    );
                  }),
                ),
              ),
            ),
            Center(
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDD000).withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          size: 56,
                          color: Color(0xFFFDD000),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "FANTASTIC!",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5F6FDB),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // THIS IS THE KEY CHANGE - ADD THE NEW PARAMETERS
                      _WinStatsAnimation(
                        timeSeconds: _timer,
                        moves: _moves,
                        fastestTime: _fastestTime,
                        fastestMoves: _fastestMoves,
                        globalFastestTime: _globalFastestTime,  // ADD THIS
                        globalFastestMoves: _globalFastestMoves, // ADD THIS
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF5F6FDB),
                                side: const BorderSide(color: Color(0xFF5F6FDB), width: 2),
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
                                backgroundColor: const Color(0xFF5F6FDB),
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
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      if (_confettiController.state == ConfettiControllerState.playing) {
        _confettiController.stop();
      }
    });
  }


  void _showPauseDialog() {
    _gameTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Center(
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
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
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5F6FDB),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 22, color: Colors.black54),
                        onPressed: () {
                          Navigator.pop(context);
                          _resumeGame();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _resumeGame();
                      },
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: const Text(
                        "RESUME",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5F6FDB),
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
                      icon: const Icon(Icons.home, size: 20),
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
      },
    );
  }

  void _resumeGame() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _timer++);
      }
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  Color _getDifficultyBackgroundColor() {
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
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              const Text("Are you sure you want to log out?",
                  textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
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
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Color(0xFF046EB8))),
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
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold)),
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
              Image.asset("assets/images-logo/mainlogo.png", width: 150, height: 50, fit: BoxFit.contain),
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
                      _buildTopNavButton("Leaderboard", Icons.leaderboard, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Leaderboard(currentUserId: widget.userAvatar),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
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
            color: Color(0xFF656BE6),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 2))],
          ),
          child: const Text(
            "Whiz Memory Match",
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
              Icon(icon, color: Colors.grey[700]),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
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
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDifficultyButton("EASY", "5 pairs", const Color(0xFF2E7D32)),
                const SizedBox(width: 18),
                _buildDifficultyButton("AVERAGE", "6 pairs", const Color(0xFF1976D2)),
                const SizedBox(width: 18),
                _buildDifficultyButton("DIFFICULT", "7 pairs", const Color(0xFFD32F2F)),
              ],
            ),
            const SizedBox(height: 34),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDD000),
                padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 14),
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
    );
  }

  Widget _buildDifficultyButton(String level, String points, Color color) {
    final isSelected = _difficulty == level;
    return GestureDetector(
      onTap: () => setState(() => _difficulty = level),
      child: Container(
        width: 210,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(22),
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
              points,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white.withValues(alpha: 0.9) : color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameBoard() {
    final totalCards = _cards.length;
    final cardsPerRow = (totalCards / 2).ceil();

    return Container(
      color: _getDifficultyBackgroundColor(),
      child: Column(
        children: [
          _buildGameStats(),
          const SizedBox(height: 48),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: List.generate(
                      cardsPerRow > _cards.length ? _cards.length : cardsPerRow,
                          (index) => _buildCard(index),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: List.generate(
                      _cards.length - cardsPerRow,
                          (index) => _buildCard(index + cardsPerRow),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildStatItem("Moves: $_moves"),
                ),
              ),
              Expanded(
                child: Center(
                  child: _buildStatItem("Score: $_score"),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.pause_circle, size: 42, color: _getDifficultyBackgroundColor()),
                  onPressed: _showPauseDialog,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 44,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getDifficultyBackgroundColor(),
              border: Border.all(color: Colors.white, width: 5),
            ),
            child: Center(
              child: Text(
                _formatTime(_timer),
                style: const TextStyle(
                  fontSize: 18,
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

  Widget _buildStatItem(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: _getDifficultyBackgroundColor(),
      ),
    );
  }

  Widget _buildCard(int index) {
    final card = _cards[index];
    final showFront = card.isFlipped || card.isMatched;
    final backImage = "assets/memorymatch/${_difficulty.toLowerCase()}.png";

    return GestureDetector(
      onTap: () {
        if (!_isChecking && !card.isMatched) _onCardTap(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 180,
        height: 270,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: card.isMatching
                ? Colors.greenAccent
                : card.isNotMatching
                ? Colors.red
                : (showFront ? _getDifficultyBorderColor() : Colors.transparent),
            width: card.isMatching || card.isNotMatching ? 4 : (showFront ? 3 : 0),
          ),
          boxShadow: [
            if (card.isMatching)
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.8),
                blurRadius: 16,
                spreadRadius: 4,
              ),
            if (card.isNotMatching)
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.8),
                blurRadius: 16,
                spreadRadius: 4,
              ),
          ],
        ),
        child: TweenAnimationBuilder<double>(
          key: ValueKey('${card.id}_${card.isFlipped}_$index'),
          duration: const Duration(milliseconds: 300),
          tween: Tween<double>(begin: showFront ? 0 : 1, end: showFront ? 1 : 0),
          builder: (context, value, _) {
            final angle = value * pi;
            final isBack = value < 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isBack
                    ? Image.asset(backImage, fit: BoxFit.cover)
                    : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: Image.asset(card.imagePath, fit: BoxFit.cover),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Win stats animation with sequential count-up and pop effects
class _WinStatsAnimation extends StatefulWidget {
  final int timeSeconds;
  final int moves;
  final int? fastestTime;
  final int? fastestMoves;
  final int? globalFastestTime;
  final int? globalFastestMoves;

  const _WinStatsAnimation({
    required this.timeSeconds,
    required this.moves,
    this.fastestTime,
    this.fastestMoves,
    this.globalFastestTime,
    this.globalFastestMoves,
  });

  @override
  State<_WinStatsAnimation> createState() => _WinStatsAnimationState();
}

class _WinStatsAnimationState extends State<_WinStatsAnimation>
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
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
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
                      color: isNewPersonalRecord ? const Color(0xFF5F6FDB) : Colors.black54,
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
                      "🏆 YOU BEAT THE RECORD! 🏆",
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

// Card model
class CardItem {
  final int id;
  final String imagePath;
  bool isFlipped;
  bool isMatched;
  bool isMatching;
  bool isNotMatching;

  CardItem({
    required this.id,
    required this.imagePath,
    this.isFlipped = false,
    this.isMatched = false,
    this.isMatching = false,
    this.isNotMatching = false,
  });
}