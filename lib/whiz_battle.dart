import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'quiz_questions.dart';
import 'services/battle_websocket_service.dart';

// ============================================================================
// DATA MODELS
// ============================================================================

class BattleRoom {
  final String gameCode;
  final String hostId;
  final String category;
  final String difficulty;
  final String? opponentId;

  BattleRoom({
    required this.gameCode,
    required this.hostId,
    required this.category,
    required this.difficulty,
    this.opponentId,
  });
}

class BattleEvent {
  static const String playerJoined = 'player_joined';
  static const String startGame = 'start_game';
  static const String scoreUpdate = 'score_update';
  static const String gameEnd = 'game_end';
  static const String playerLeft = 'player_left';
  static const String error = 'error';
}

// ============================================================================
// MAIN BATTLE SCREEN (Room Creation/Join)
// ============================================================================

class WhizBattle extends StatefulWidget {
  final String userAvatar;
  final String userId;
  final String username;

  const WhizBattle({
    super.key,
    required this.userAvatar,
    required this.userId,
    required this.username,
  });

  @override
  State<WhizBattle> createState() => _WhizBattleState();
}

class _WhizBattleState extends State<WhizBattle> {
  final TextEditingController _roomCodeController = TextEditingController();
  String _selectedCategory = "Science";
  String _selectedDifficulty = "EASY";
  bool _isCreatingRoom = false;

  final List<String> categories = [
    "Science",
    "Mathematics",
    "History",
    "Geography",
    "Technology"
  ];

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  Future<void> _createRoom() async {
    if (_isCreatingRoom) return;

    setState(() => _isCreatingRoom = true);

    final roomCode = _generateRoomCode();
    final wsService = BattleWebSocketService();

    final connected = await wsService.connect(widget.userId);

    if (!connected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to server')),
        );
        setState(() => _isCreatingRoom = false);
      }
      return;
    }

    await Future.delayed(const Duration(milliseconds: 300));

    final battleRoom = BattleRoom(
      gameCode: roomCode,
      hostId: widget.userId,
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
    );

    wsService.createRoom(
      roomCode: roomCode,
      hostName: widget.username,
      hostAvatar: widget.userAvatar,
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
    );

    if (mounted) {
      setState(() => _isCreatingRoom = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BattleGameScreen(
            battleRoom: battleRoom,
            userId: widget.userId,
            username: widget.username,
            userAvatar: widget.userAvatar,
            isHost: true,
            webSocketService: wsService,
          ),
        ),
      );
    }
  }

  Future<void> _joinRoom() async {
    final roomCode = _roomCodeController.text.trim().toUpperCase();

    if (roomCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a room code')),
      );
      return;
    }

    setState(() => _isCreatingRoom = true);

    final wsService = BattleWebSocketService();

    final connected = await wsService.connect(widget.userId);

    if (!connected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to server')),
        );
        setState(() => _isCreatingRoom = false);
      }
      return;
    }

    await Future.delayed(const Duration(milliseconds: 300));

    final battleRoom = BattleRoom(
      gameCode: roomCode,
      hostId: 'opponent_id',
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
      opponentId: widget.userId,
    );

    wsService.joinRoom(
      roomCode: roomCode,
      playerName: widget.username,
      playerAvatar: widget.userAvatar,
    );

    if (mounted) {
      setState(() => _isCreatingRoom = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BattleGameScreen(
            battleRoom: battleRoom,
            userId: widget.userId,
            username: widget.username,
            userAvatar: widget.userAvatar,
            isHost: false,
            webSocketService: wsService,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC571E2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC571E2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Whiz Battle',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFC571E2), width: 4),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      widget.userAvatar,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  widget.username,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 30),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value!);
                  },
                ),
                const SizedBox(height: 15),
                const Text(
                  'Select Difficulty',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDifficultyButton('EASY', const Color(0xFF1D9358)),
                    _buildDifficultyButton('AVERAGE', const Color(0xFF046EB8)),
                    _buildDifficultyButton('DIFFICULT', const Color(0xFFBD442E)),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCreatingRoom ? null : _createRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC571E2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: _isCreatingRoom
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      'CREATE BATTLE ROOM',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('OR'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _roomCodeController,
                  decoration: InputDecoration(
                    labelText: 'Enter Room Code',
                    hintText: 'ABC123',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isCreatingRoom ? null : _joinRoom,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC571E2),
                      side: const BorderSide(color: Color(0xFFC571E2), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isCreatingRoom
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Color(0xFFC571E2),
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      'JOIN BATTLE ROOM',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
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

  Widget _buildDifficultyButton(String difficulty, Color color) {
    final isSelected = _selectedDifficulty == difficulty;

    return GestureDetector(
      onTap: () => setState(() => _selectedDifficulty = difficulty),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          difficulty,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BATTLE GAME SCREEN (Actual Gameplay)
// ============================================================================

class BattleGameScreen extends StatefulWidget {
  final BattleRoom battleRoom;
  final String userId;
  final String username;
  final String userAvatar;
  final bool isHost;
  final BattleWebSocketService webSocketService;

  const BattleGameScreen({
    super.key,
    required this.battleRoom,
    required this.userId,
    required this.username,
    required this.userAvatar,
    required this.isHost,
    required this.webSocketService,
  });

  @override
  State<BattleGameScreen> createState() => _BattleGameScreenState();
}

class _BattleGameScreenState extends State<BattleGameScreen> {
  List<Question> questions = [];
  int currentQuestionIndex = 0;
  int myScore = 0;
  int opponentScore = 0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showFeedback = false;
  bool _wasCorrect = false;
  int _currentQuestionScore = 0;
  bool _waitingForOpponent = false;

  String opponentName = "Waiting...";
  String opponentAvatar = "assets/images-avatars/default.png";
  bool opponentJoined = false;
  bool gameStarted = false;

  final int totalQuestions = 10;

  Timer? _questionTimer;
  int _timeRemaining = 15;
  static const int maxTimePerQuestion = 15;

  late StreamSubscription _wsSubscription;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();

    _listenToWebSocket();
    _loadQuestions();

    if (!widget.isHost) {
      setState(() {
        opponentJoined = true;
      });
    }

    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (!gameStarted && mounted) {
        if (kDebugMode) debugPrint('⏰ TIMEOUT: Game did not start');
        setState(() {
          _errorMessage = 'Game failed to start. The server may not have sent the start signal.';
        });
      }
    });

    if (kDebugMode) {
      debugPrint('🎮 BattleGameScreen initialized');
      debugPrint('🎮 isHost: ${widget.isHost}');
      debugPrint('🎮 Room Code: ${widget.battleRoom.gameCode}');
    }
  }

  @override
  void dispose() {
    _wsSubscription.cancel();
    _timeoutTimer?.cancel();
    _questionTimer?.cancel();

    widget.webSocketService.leaveRoom(widget.battleRoom.gameCode);
    widget.webSocketService.disconnect();

    super.dispose();
  }

  void _startQuestionTimer() {
    _timeRemaining = maxTimePerQuestion;
    _questionTimer?.cancel();

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeRemaining > 0) {
            _timeRemaining--;
          } else {
            timer.cancel();
            _handleAnswer('');
          }
        });
      }
    });
  }

  void _stopQuestionTimer() {
    _questionTimer?.cancel();
  }

  void _listenToWebSocket() {
    if (kDebugMode) debugPrint('👂 Setting up WebSocket listener...');

    _wsSubscription = widget.webSocketService.messages.listen(
          (message) {
        final event = message['event'];

        if (kDebugMode) {
          debugPrint('🎮 Game Screen Received Event: $event');
          debugPrint('🎮 Full Message: $message');
        }

        if (!mounted) return;

        switch (event) {
          case BattleEvent.playerJoined:
            if (kDebugMode) debugPrint('👥 Player joined event received');
            setState(() {
              final player = message['player'];
              opponentName = player['name'] ?? 'Opponent';
              opponentAvatar = player['avatar'] ?? opponentAvatar;
              opponentJoined = true;
            });

            if (widget.isHost) {
              if (kDebugMode) debugPrint('🎮 Host starting game in 2 seconds...');
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  if (kDebugMode) debugPrint('📤 Host sending start_game command');
                  widget.webSocketService.startGame(widget.battleRoom.gameCode);
                }
              });
            }
            break;

          case BattleEvent.startGame:
            if (kDebugMode) debugPrint('🚀 START GAME EVENT RECEIVED!');
            setState(() {
              gameStarted = true;
            });
            _timeoutTimer?.cancel();
            _startQuestionTimer();
            break;

          case 'next_question':
            if (kDebugMode) debugPrint('➡️ Moving to next question');
            if (mounted) {
              _nextQuestion();
            }
            break;

          case BattleEvent.scoreUpdate:
            final playerId = message['player_id'];
            if (playerId != widget.userId) {
              final newScore = message['score'] ?? 0;
              if (kDebugMode) debugPrint('📊 Opponent score update: $newScore');
              setState(() {
                opponentScore = newScore;
              });
            }
            break;

          case BattleEvent.gameEnd:
            if (kDebugMode) debugPrint('🏁 Game end event received');
            _stopQuestionTimer();
            _showResults(
              winnerId: message['winner_id'] ?? '',
              finalScores: message['final_scores'] ?? {},
            );
            break;

          case BattleEvent.playerLeft:
          case 'player_disconnected':
            if (kDebugMode) debugPrint('👋 Opponent left');
            _stopQuestionTimer();
            _showOpponentLeftDialog();
            break;

          case BattleEvent.error:
            if (kDebugMode) debugPrint('❌ Error event: ${message['message']}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message['message'] ?? 'An error occurred')),
              );
            }
            break;

          default:
            if (kDebugMode) debugPrint('❓ Unknown event: $event');
        }
      },
      onError: (error) {
        if (kDebugMode) debugPrint('❌ WebSocket listener error: $error');
      },
    );

    if (kDebugMode) debugPrint('✅ WebSocket listener set up complete');
  }

  void _loadQuestions() async {
    try {
      final normalizedDifficulty = widget.battleRoom.difficulty.toUpperCase();
      final allQuestions = await QuizData.getQuestions(
        widget.battleRoom.category,
        normalizedDifficulty,
      );

      if (allQuestions.isEmpty) {
        setState(() {
          _errorMessage = 'No questions available';
          _isLoading = false;
        });
        return;
      }

      final seed = widget.battleRoom.gameCode.hashCode;
      final random = Random(seed);

      final shuffled = List<Question>.from(allQuestions);
      for (var i = shuffled.length - 1; i > 0; i--) {
        final j = random.nextInt(i + 1);
        final temp = shuffled[i];
        shuffled[i] = shuffled[j];
        shuffled[j] = temp;
      }

      questions = shuffled.take(totalQuestions).toList();

      setState(() {
        _isLoading = false;
      });

      if (kDebugMode) debugPrint('✅ Loaded ${questions.length} questions with seed: $seed');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to load questions: $e');
      setState(() {
        _errorMessage = 'Failed to load questions: $e';
        _isLoading = false;
      });
    }
  }

  void _handleAnswer(String answer) {
    if (_showFeedback) return;

    _stopQuestionTimer();

    final isCorrect = answer == questions[currentQuestionIndex].correctAnswer;

    _currentQuestionScore = isCorrect ? _timeRemaining : 0;

    setState(() {
      _wasCorrect = isCorrect;
      myScore += _currentQuestionScore;
      _showFeedback = true;
      _waitingForOpponent = true;
    });

    if (kDebugMode) {
      debugPrint('📝 Answer submitted: ${isCorrect ? "Correct" : "Wrong"}');
      debugPrint('📝 Points earned: $_currentQuestionScore');
      debugPrint('📝 Current question: ${currentQuestionIndex + 1}/${questions.length}');
    }

    widget.webSocketService.submitAnswer(
      roomCode: widget.battleRoom.gameCode,
      isCorrect: isCorrect,
      points: _currentQuestionScore,
    );

    if (currentQuestionIndex >= questions.length - 1) {
      if (kDebugMode) debugPrint('📝 Last question answered, waiting for game_end event');
    }
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        _showFeedback = false;
        _wasCorrect = false;
        _currentQuestionScore = 0;
        _waitingForOpponent = false;
      });
      _startQuestionTimer();
    } else {
      if (kDebugMode) debugPrint('⏳ Waiting for game results...');
    }
  }

  void _showResults({required String winnerId, required Map<String, dynamic> finalScores}) {
    final didIWin = winnerId == widget.userId;

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => BattleResultScreen(
          category: widget.battleRoom.category,
          difficulty: widget.battleRoom.difficulty,
          gameCode: widget.battleRoom.gameCode,
          myScore: myScore,
          opponentScore: opponentScore,
          myName: widget.username,
          opponentName: opponentName,
          myAvatar: widget.userAvatar,
          opponentAvatar: opponentAvatar,
          totalQuestions: questions.length,
          didIWin: didIWin,
        ),
      ),
    );
  }

  void _showOpponentLeftDialog() {
    _stopQuestionTimer();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 32),
              const SizedBox(width: 10),
              const Text(
                'Battle Ended',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Your opponent has left the battle room. The room has been dissolved.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                widget.webSocketService.disconnect();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC571E2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (widget.battleRoom.difficulty.toUpperCase()) {
      case "EASY":
        return const Color(0xFF1D9358);
      case "AVERAGE":
        return const Color(0xFF046EB8);
      case "DIFFICULT":
        return const Color(0xFFBD442E);
      default:
        return const Color(0xFF1D9358);
    }
  }

  @override
  Widget build(BuildContext context) {
    final difficultyColor = _getDifficultyColor();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Leave Battle?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Are you sure you want to leave? This will end the battle and your opponent will be notified.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'LEAVE',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

        if (shouldLeave == true && context.mounted) {
          widget.webSocketService.leaveRoom(widget.battleRoom.gameCode);
          widget.webSocketService.disconnect();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _buildBody(difficultyColor),
      ),
    );
  }

  Widget _buildBody(Color difficultyColor) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: difficultyColor),
            const SizedBox(height: 20),
            const Text('Loading questions...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  widget.webSocketService.leaveRoom(widget.battleRoom.gameCode);
                  widget.webSocketService.disconnect();
                  Navigator.pop(context);
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.isHost && !opponentJoined) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Waiting for opponent to join...',
              style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: difficultyColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Room Code: ${widget.battleRoom.gameCode}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!gameStarted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Starting game...',
              style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 20),
            Text(
              'Opponent: ${opponentJoined ? opponentName : "Not joined yet"}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final question = questions[currentQuestionIndex];

    return Column(
        children: [
        _buildHeader(difficultyColor),
    Expanded(
    child: _showFeedback
    // PART 1: Copy lines 1-500 from the artifact above

// PART 2: Continue with the rest (starting from _buildFeedbackView)
        ? _buildFeedbackView()
        : _buildQuestionView(question),
    ),
        ],
    );
  }

  Widget _buildHeader(Color difficultyColor) {
    return Container(
      width: double.infinity,
      color: difficultyColor,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "${widget.battleRoom.category.toUpperCase()}\n${widget.battleRoom.difficulty.toUpperCase()}",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
                height: 1.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Game Code: ${widget.battleRoom.gameCode}",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionView(Question question) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildScoreBoard(),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _timeRemaining <= 5 ? Colors.red.withValues(alpha:0.1): const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _timeRemaining <= 5 ? Colors.red : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      color: _timeRemaining <= 5 ? Colors.red : Colors.blue,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "$_timeRemaining seconds",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: _timeRemaining <= 5 ? Colors.red : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Question: ${currentQuestionIndex + 1} of ${questions.length}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF046EB8), width: 2),
                ),
                child: Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 18,
                  childAspectRatio: 2.8,
                ),
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  return _buildAnswerButton(question.options[index], index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPlayerCard(widget.username, widget.userAvatar, myScore, true),
        const Text(
          "VS",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF046EB8),
            fontFamily: 'Poppins',
          ),
        ),
        _buildPlayerCard(opponentName, opponentAvatar, opponentScore, false),
      ],
    );
  }

  Widget _buildPlayerCard(String name, String avatar, int score, bool isMe) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? const Color(0xFF046EB8) : const Color(0xFFBD442E),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isMe ? const Color(0xFF046EB8) : const Color(0xFFBD442E),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                avatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.person),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Color(0xFFFDD000), size: 20),
              const SizedBox(width: 4),
              Text(
                "$score",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(String answer, int index) {
    final colors = [
      const Color(0xFF046EB8),
      const Color(0xFFF39C12),
      const Color(0xFFE67E22),
      const Color(0xFF9B59B6),
    ];
    final buttonColor = colors[index % colors.length];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _handleAnswer(answer),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: buttonColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: 'Poppins',
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackView() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildScoreBoard(),
            const SizedBox(height: 40),
            Text(
              _wasCorrect ? "CORRECT ANSWER!" : "WRONG ANSWER!",
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: _wasCorrect ? const Color(0xFF1D9358) : const Color(0xFFE74C3C),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 20),
            if (_wasCorrect)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9358).withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF1D9358), width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFDD000), size: 32),
                    const SizedBox(width: 10),
                    Text(
                      "+$_currentQuestionScore points",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D9358),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Text(
              "Correct Answer: ${questions[currentQuestionIndex].correctAnswer}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            if (_waitingForOpponent) ...[
              const SizedBox(height: 30),
              const CircularProgressIndicator(),
              const SizedBox(height: 15),
              const Text(
                "Waiting for opponent...",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BATTLE RESULT SCREEN
// ============================================================================

class BattleResultScreen extends StatelessWidget {
  final String category;
  final String difficulty;
  final String gameCode;
  final int myScore;
  final int opponentScore;
  final String myName;
  final String opponentName;
  final String myAvatar;
  final String opponentAvatar;
  final int totalQuestions;
  final bool didIWin;

  const BattleResultScreen({
    super.key,
    required this.category,
    required this.difficulty,
    required this.gameCode,
    required this.myScore,
    required this.opponentScore,
    required this.myName,
    required this.opponentName,
    required this.myAvatar,
    required this.opponentAvatar,
    required this.totalQuestions,
    required this.didIWin,
  });

  Color _getDifficultyColor() {
    switch (difficulty.toUpperCase()) {
      case "EASY":
        return const Color(0xFF1D9358);
      case "AVERAGE":
        return const Color(0xFF046EB8);
      case "DIFFICULT":
        return const Color(0xFFBD442E);
      default:
        return const Color(0xFF1D9358);
    }
  }

  @override
  Widget build(BuildContext context) {
    final difficultyColor = _getDifficultyColor();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(difficultyColor),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Stack(
                          children: [
                            Text(
                              didIWin ? "VICTORY" : "DEFEAT",
                              style: TextStyle(
                                fontSize: 70,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                letterSpacing: 2,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 8
                                  ..color = didIWin
                                      ? const Color(0xFFAC8337)
                                      : const Color(0xFF631F13),
                              ),
                            ),
                            Text(
                              didIWin ? "VICTORY" : "DEFEAT",
                              style: TextStyle(
                                fontSize: 70,
                                fontWeight: FontWeight.bold,
                                color: didIWin
                                    ? const Color(0xFFFDD000)
                                    : const Color(0xFF808080),
                                fontFamily: 'Poppins',
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPlayerResult(myName, myAvatar, myScore, true),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              "$myScore : $opponentScore",
                              style: const TextStyle(
                                fontSize: 80,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          _buildPlayerResult(opponentName, opponentAvatar, opponentScore, false),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Text(
                        "Questions Completed: $totalQuestions of $totalQuestions",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1D9358),
                              side: const BorderSide(color: Color(0xFF1D9358), width: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              "EXIT GAME",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D9358),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
                              "PLAY AGAIN",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color difficultyColor) {
    return Container(
      width: double.infinity,
      color: difficultyColor,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "${category.toUpperCase()}\n${difficulty.toUpperCase()}",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
                height: 1.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Game Code: $gameCode",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerResult(String name, String avatar, int score, bool isMe) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isMe ? const Color(0xFF046EB8) : const Color(0xFFBD442E),
              width: 4,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              avatar,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, size: 60),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Color(0xFFFDD000), size: 24),
            const SizedBox(width: 6),
            Text(
              "$score",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ],
    );
  }
}