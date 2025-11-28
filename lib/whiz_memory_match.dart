import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';

class WhizMemoryMatch extends StatefulWidget {
  final String userAvatar;

  const WhizMemoryMatch({
    super.key,
    this.userAvatar = "assets/images-avatars/Adventurer.png",
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

  List<CardItem> _cards = [];
  List<int> _flippedIndices = [];
  bool _isChecking = false;

  late final ConfettiController _confettiController;
  // used to drive score animation in the win dialog
  int _lastFinalScore = 0;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _startGame() {
    // Reset and generate cards based on difficulty
    setState(() {
      _gameStarted = true;
      _moves = 0;
      _score = 0;
      _timer = 0;
      _generateCards();
    });

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _timer++);
      }
    });
  }

  void _generateCards() {
    final pairs = _difficulty == "EASY"
        ? 5
        : (_difficulty == "AVERAGE" ? 6 : 7); // keep your logic
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

      // reset visual flags
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
      _lastFinalScore = _score;
      _showWinDialog();
    }
  }

  void _showWinDialog() {
    // play confetti first (positioned behind the dialog)
    _confettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        // Use a Stack so confetti can be behind the Dialog
        return Stack(
          alignment: Alignment.center,
          children: [
            // Full-screen confetti behind dialog
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  emissionFrequency: 0.03,
                  numberOfParticles: 40,
                  maxBlastForce: 12,
                  minBlastForce: 4,
                  gravity: 0.25,
                  colors: const [
                    Color(0xFFFDD000),
                    Color(0xFF5F6FDB),
                    Color(0xFF046EB8),
                    Colors.red,
                    Colors.green,
                    Colors.orange,
                  ],
                ),
              ),
            ),

            // Centered dialog
            Center(
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
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
                          color: const Color(0xFFFDD000).withValues(alpha:0.18),
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

                      // Animated counters area: Time Played + Score (animated)
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 400),
                        opacity: 1.0,
                        child: Column(
                          children: [
                            _AnimatedCounterRow(
                              label: "Time Played:",
                              value: _formatTime(_timer),
                            ),
                            const SizedBox(height: 8),
                            // Score animating count up: uses _lastFinalScore
                            _AnimatedScoreRow(
                              label: "Score:",
                              score: _lastFinalScore,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // close both dialogs and pop screen
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF5F6FDB),
                                side: const BorderSide(
                                    color: Color(0xFF5F6FDB), width: 2),
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text(
                                "EXIT",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                // restart game
                                _startGame();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5F6FDB),
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                              ),
                              child: const Text(
                                "PLAY AGAIN",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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
      // Stop confetti after dialog closed (safety)
      if (_confettiController.state == ConfettiControllerState.playing) {
        _confettiController.stop();
      }
    });
  }

  void _showPauseDialog() {
    // pause timer
    _gameTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Center(
          child: Dialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Container(
              width: 320,
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
                        icon: const Icon(Icons.close,
                            size: 22, color: Colors.black54),
                        onPressed: () {
                          Navigator.pop(context);
                          _resumeGame();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
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
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5F6FDB),
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // exit to previous route (close two levels)
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.home, size: 20),
                      label: const Text(
                        "EXIT",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black54,
                        side:
                        const BorderSide(color: Colors.black26, width: 2),
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
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
    // restart periodic timer
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
              Image.asset("assets/images-icons/sadlogout.png",
                  width: 80, height: 80),
              const SizedBox(height: 15),
              const Text("Logout Confirmation",
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
              const SizedBox(height: 10),
              const Text("Are you sure you want to log out?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF046EB8), width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Cancel",
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Color(0xFF046EB8))),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Logout",
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
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

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildTopBar(),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          margin: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Image.asset("assets/images-logo/mainlogo.png",
                  width: 150, height: 50, fit: BoxFit.contain),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTopNavButton("Home", Icons.home, () {
                        if (_gameStarted) {
                          _showExitGameDialog();
                        } else {
                          Navigator.pop(context);
                        }
                      }),
                      const SizedBox(width: 36),
                      _buildTopNavButton("Leaderboard", Icons.leaderboard, () {
                        // placeholder navigation
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
                      border:
                      Border.all(color: const Color(0xFF046EB8), width: 3),
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
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 2))
            ],
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

  void _showExitGameDialog() {
    _gameTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getDifficultyBackgroundColor().withValues(alpha:0.9),
                  _getDifficultyBackgroundColor(),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.28),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.exit_to_app,
                    size: 45,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "End Round?",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Your progress will be lost!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _resumeGame();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _getDifficultyBackgroundColor(),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Keep Playing",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text(
                          "End Round",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
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
                color: isSelected ? Colors.white.withValues(alpha:0.9) : color.withValues(alpha:0.8),
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
        width: 160,
        height: 240,
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
                color: Colors.greenAccent.withValues(alpha:0.8),
                blurRadius: 16,
                spreadRadius: 4,
              ),
            if (card.isNotMatching)
              BoxShadow(
                color: Colors.red.withValues(alpha:0.8),
                blurRadius: 16,
                spreadRadius: 4,
              ),
          ],
        ),
        child: card.isMatched
            ? ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(card.imagePath, fit: BoxFit.cover),
        )
            : TweenAnimationBuilder<double>(
          key: ValueKey('${card.id}_${card.isFlipped}_$index'),
          duration: const Duration(milliseconds: 420),
          tween: Tween<double>(begin: showFront ? 0 : 1, end: showFront ? 1 : 0),
          builder: (context, value, _) {
            // value 0 -> back, 1 -> front, so rotate by pi * value
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

// Small animated counter row (text label + value)
class _AnimatedCounterRow extends StatefulWidget {
  final String label;
  final String value;

  const _AnimatedCounterRow({required this.label, required this.value});

  @override
  State<_AnimatedCounterRow> createState() => _AnimatedCounterRowState();
}

class _AnimatedCounterRowState extends State<_AnimatedCounterRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedCounterRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(_anim),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.label, style: const TextStyle(fontSize: 15, color: Colors.black87)),
            const SizedBox(width: 8),
            Text(widget.value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF5F6FDB))),
          ],
        ),
      ),
    );
  }
}

// Animated score row that counts from 0 -> score
class _AnimatedScoreRow extends StatefulWidget {
  final String label;
  final int score;

  const _AnimatedScoreRow({required this.label, required this.score});

  @override
  State<_AnimatedScoreRow> createState() => _AnimatedScoreRowState();
}

class _AnimatedScoreRowState extends State<_AnimatedScoreRow> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 6),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: widget.score),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Text(
              "$value",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF5F6FDB)),
            );
          },
        ),
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