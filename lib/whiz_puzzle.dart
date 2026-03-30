import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:confetti/confetti.dart';
import 'audio_service.dart';
import 'game_tutorial_overlay.dart';
import 'loading_page.dart';

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
  bool _isNewPersonalRecord = false;
  bool _isNewBestTime = false;
  int _starsEarned = 0;
  int _totalStars = 0;
  Map<String, dynamic>? _newMilestone;
  Map<String, dynamic>? _currentTier;
  late final ConfettiController _confettiController;

  int? _globalFastestTime;
  int? _fastestTime;
  bool _showGameTutorial = false;
  bool _checkingTutorialStatus = true;
  final String baseUrl = "http://localhost:8000";
  Timer? _gameTimer;

  late int _gridSize;

  List<PuzzlePiece> _pieces = [];
  String? _imageUrl;

  // Difficulty options
  bool _isMusicEnabled = true; // ✅ Music toggle
  final List<Map<String, String>> difficultyLevels = [
    {'value': 'EASY', 'display': 'Easy', 'grid': '3x3 grid'},
    {'value': 'AVERAGE', 'display': 'Average', 'grid': '4x4 grid'},
    {'value': 'DIFFICULT', 'display': 'Difficult', 'grid': '5x5 grid'},
  ];

  // Categories with their images
  final List<Map<String, String>> categories = [
    {
      'name': 'Solar System',
      'image': 'assets/puzzle/solar_system.png',
    },
    {
      'name': 'Scientists',
      'image': 'assets/puzzle/scientists.jpg',
    },
    {
      'name': 'Human Body',
      'image': 'assets/puzzle/human_body.png',
    },
    {
      'name': 'Animals',
      'image': 'assets/puzzle/animals.jpg',
    },
    {
      'name': 'Geometry',
      'image': 'assets/puzzle/geometry.jpg',
    },
    {
      'name': 'Starbooks',
      'image': 'assets/puzzle/starbookswhiz.jpeg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGameTutorialStatus();
      AudioService().playPuzzleMusic(); // ✅ Start music on selection screen
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _startGame() {
    AudioService().playPuzzleMusic(); // ✅ Start puzzle music when game begins
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
      _isNewPersonalRecord = false;
      _isNewBestTime = false;
      _starsEarned = 0;
      _totalStars = 0;
      _newMilestone = null;
      _currentTier = null;
      _initializePuzzle();
    });

    _loadFastestTime();

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isPaused && !_isCompleted) {
        setState(() => _timer++);
      }
    });
  }

  Future<void> _checkGameTutorialStatus() async {
    try {
      final shouldShow = await GameTutorialOverlay.shouldShowTutorial(
        widget.playerId,
        'puzzle',
      );

      if (shouldShow && mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _showGameTutorial = true;
            _checkingTutorialStatus = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _checkingTutorialStatus = false);
        }
      }
    } catch (e) {
      debugPrint('Error checking game tutorial status: $e');
      if (mounted) {
        setState(() => _checkingTutorialStatus = false);
      }
    }
  }

  Future<void> _loadFastestTime() async {
    try {
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
          debugPrint('Personal fastest time: $_fastestTime');
        } else {
          setState(() => _fastestTime = null);
        }
      }

      // ✅ FIX: Load global time in parallel instead of chained after personal time
      _loadGlobalFastestTime();
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
    final cat = categories.firstWhere(
          (c) => c['name'] == category,
      orElse: () => categories[0],
    );
    return cat['image']!;
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  Future<void> _checkCompletion() async {
    if (_pieces.every((piece) => piece.isLocked)) {
      setState(() {
        _isCompleted = true;
        _gameTimer?.cancel();
      });

      // ✅ Show loading dialog IMMEDIATELY so user sees feedback right away
      if (mounted) {
        LoadingHelper.showLoadingDialog(
          context,
          message: 'Calculating results...',
          width: 350,
          height: 250,
        );
      }

      // ✅ FIX: Determine new best time BEFORE any API call
      final bool newBestTime = _globalFastestTime != null && _timer < _globalFastestTime!;
      setState(() => _isNewBestTime = newBestTime);

      // ✅ FIX: Run save + award in parallel
      await Future.wait([
        _saveFastestTime(),
        _awardStars(),
      ]);

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          LoadingHelper.hideLoading(context);
          if (mounted) {
            _showResultsPage();
          }
        }
      }
    }
  }

  Future<void> _saveFastestTime() async {
    try {
      debugPrint('Saving fastest time: $_timer seconds for difficulty: $_difficulty, category: $_category');

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

      debugPrint('Save fastest time response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        bool isNewRecord = data['is_new_record'] ?? false;

        // Guard against race condition: _fastestTime may still be null if
        // _loadFastestTime() hadn't finished before the game ended.
        // If we had a previous personal best loaded, only trust isNewRecord
        // if our current time actually beats it. If _fastestTime was null
        // (no prior record confirmed), treat it as a genuine first-time record.
        if (isNewRecord && _fastestTime != null && _timer >= _fastestTime!) {
          isNewRecord = false;
        }

        // ✅ FIX: Update state directly from save response — no redundant re-fetch
        setState(() {
          _isNewPersonalRecord = isNewRecord;
          // Update personal best in memory if this run was faster
          if (_fastestTime == null || _timer < _fastestTime!) {
            _fastestTime = _timer;
          }
        });

        debugPrint('Is new personal record: $isNewRecord');
        // ❌ REMOVED: await _loadFastestTime() + await _loadGlobalFastestTime()
        // Those were causing 2 extra sequential API calls after every game finish
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
              const Icon(Icons.warning_amber, size: 60, color: Color(0xFFE6833A)),
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
                onPressed: () async {
                  try {
                    await AudioService().playClickSound();
                  } catch (e) {
                    debugPrint('Click sound not found: $e');
                  }
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE6833A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  "OK",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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
                          color: Color(0xFFE6833A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 22, color: Colors.black54),
                        onPressed: () async {
                          try {
                            await AudioService().playClickSound();
                          } catch (e) {
                            debugPrint('Click sound not found: $e');
                          }
                          Navigator.pop(context);
                          setState(() => _isPaused = false);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ✅ Music mute/unmute toggle
                  StatefulBuilder(
                    builder: (context, setDialogState) {
                      return Container(
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              Icon(_isMusicEnabled ? Icons.music_note : Icons.music_off,
                                  color: _difficultyColor(_difficulty), size: 22),
                              const SizedBox(width: 10),
                              const Text('Music', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600)),
                            ]),
                            Switch(
                              value: _isMusicEnabled,
                              activeColor: _difficultyColor(_difficulty),
                              onChanged: (val) {
                                setState(() => _isMusicEnabled = val);
                                setDialogState(() {});
                                if (val) {
                                  AudioService().resumeMusic().catchError((_) => AudioService().playPuzzleMusic());
                                } else {
                                  AudioService().pauseMusic();
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // RESUME BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await AudioService().playClickSound();
                        } catch (e) {
                          debugPrint('Click sound not found: $e');
                        }
                        Navigator.pop(context);
                        setState(() => _isPaused = false);
                      },
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: const Text(
                        "RESUME",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _difficultyColor(_difficulty),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // RESTART BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await AudioService().playClickSound();
                        } catch (e) {
                          debugPrint('Click sound not found: $e');
                        }
                        Navigator.pop(context);

                        final confirmed = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Container(
                              width: 400,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.refresh, color: Color(0xFFE6833A), size: 60),
                                  const SizedBox(height: 15),
                                  const Text(
                                    "Restart Game",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Do you really want to restart? Your current progress will be lost.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                                  ),
                                  const SizedBox(height: 25),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () async {
                                            try {
                                              await AudioService().playClickSound();
                                            } catch (e) {
                                              debugPrint('Click sound not found: $e');
                                            }
                                            Navigator.pop(context, false);
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            side: const BorderSide(color: Color(0xFFE6833A), width: 1),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          ),
                                          child: const Text(
                                            "No",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              color: Color(0xFFE6833A),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              await AudioService().playClickSound();
                                            } catch (e) {
                                              debugPrint('Click sound not found: $e');
                                            }
                                            Navigator.pop(context, true);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFE6833A),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          ),
                                          child: const Text(
                                            "Yes",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
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
                        );

                        if (confirmed == true && mounted) {
                          setState(() => _isPaused = false);
                          _startGame();
                        } else if (mounted) {
                          setState(() => _isPaused = false);
                        }
                      },
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text(
                        "RESTART",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDD000),
                        foregroundColor: const Color(0xFF816A03),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // EXIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await AudioService().playClickSound();
                        } catch (e) {
                          debugPrint('Click sound not found: $e');
                        }
                        Navigator.pop(context);

                        final confirmed = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Container(
                              width: 400,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.exit_to_app, color: Colors.red, size: 60),
                                  const SizedBox(height: 15),
                                  const Text(
                                    "Exit Game",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Do you want to exit? Your current progress will be lost.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                                  ),
                                  const SizedBox(height: 25),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () async {
                                            try {
                                              await AudioService().playClickSound();
                                            } catch (e) {
                                              debugPrint('Click sound not found: $e');
                                            }
                                            Navigator.pop(context, false);
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            side: const BorderSide(color: Color(0xFFE6833A), width: 1),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          ),
                                          child: const Text(
                                            "No",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              color: Color(0xFFE6833A),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              await AudioService().playClickSound();
                                            } catch (e) {
                                              debugPrint('Click sound not found: $e');
                                            }
                                            Navigator.pop(context, true);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          ),
                                          child: const Text(
                                            "Yes",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
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
                        );

                        if (confirmed == true && mounted) {
                          AudioService().playHomepageMusic(); // ✅ Restore homepage music
                          Navigator.pop(context); // Exit to homepage
                        } else if (mounted) {
                          setState(() => _isPaused = false);
                        }
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

  void _showResultsPage() {
    _confettiController.play();
    // Music keeps playing through the results page

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PuzzleResultsPage(
          difficulty: _difficulty,
          category: _category ?? '',
          starsEarned: _starsEarned,
          yourTime: _timer,
          bestTime: _globalFastestTime ?? _timer,
          personalBest: _fastestTime ?? _timer,
          totalStars: _totalStars,
          moves: _moves,
          isNewBestTime: _isNewBestTime,
          isNewPersonalRecord: _isNewPersonalRecord,
          newMilestone: _newMilestone,
          currentTier: _currentTier,
          onPlayAgain: () {
            Navigator.pop(context);
            _startGame();
          },
          onExit: () {
            Navigator.pop(context); // Close results page
            AudioService().playHomepageMusic(); // ✅ Restore homepage music on exit
            Navigator.pop(context); // Go back to homepage
          },
        ),
      ),
    );
  }

  Future<void> _awardStars() async {
    try {
      int starsEarned = _calculateStars();
      debugPrint('Awarding $starsEarned stars for difficulty: $_difficulty');

      final response = await http.post(
        Uri.parse('$baseUrl/api/players/${widget.playerId}/stars'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'stars': starsEarned,
          'game_type': 'puzzle',
          'difficulty': _difficulty,
        }),
      );

      debugPrint('Stars API response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _starsEarned = starsEarned;
          _totalStars = data['total_stars'];
          _newMilestone = data['new_milestone'];
          _currentTier = data['current_tier'] != null
              ? Map<String, dynamic>.from(data['current_tier'])
              : null;
        });
      } else {
        debugPrint('Failed to award stars: ${response.statusCode}');
        setState(() {
          _starsEarned = starsEarned;
        });
      }
    } catch (e) {
      debugPrint('Error awarding stars: $e');
      setState(() {
        _starsEarned = _calculateStars();
      });
    }
  }

  int _calculateStars() {
    final baseStars = _difficulty == "EASY" ? 1 : (_difficulty == "AVERAGE" ? 2 : 3);

    if (_globalFastestTime == null) {
      return baseStars * 5;
    }

    final performanceRatio = _globalFastestTime! / _timer;

    if (performanceRatio >= 1.0) {
      return baseStars * 5;
    } else if (performanceRatio >= 0.8) {
      return baseStars * 3;
    } else if (performanceRatio >= 0.6) {
      return baseStars * 2;
    } else {
      return baseStars;
    }
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
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading global fastest time: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: _checkingTutorialStatus
              ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFE6833A)),
          )
              : _gameStarted
              ? _buildGameBoard()
              : Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: _buildSelectionScreen(),
              ),
            ],
          ),
        ),
        if (_showGameTutorial)
          GameTutorialOverlay(
            userId: widget.playerId,
            gameType: 'puzzle',
            onComplete: () {
              setState(() => _showGameTutorial = false);
            },
          ),
      ],
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
              Image.asset(
                "assets/images-logo/newhomepagelogo.png",
                width: 150,
                height: 50,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () async {
                    try {
                      await AudioService().playClickSound();
                    } catch (e) {
                      debugPrint('Click sound not found: $e');
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE6833A), width: 3),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFFE6833A),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () async {
                  try {
                    await AudioService().playClickSound();
                  } catch (e) {
                    debugPrint('Click sound not found: $e');
                  }
                  AudioService().playHomepageMusic(); // ✅ Restore homepage music on back
                  Navigator.pop(context);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Expanded(child: SizedBox()),
              const Text(
                "Whiz Puzzle",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Expanded(child: SizedBox()),
              const SizedBox(width: 28),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionScreen() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DIFFICULTY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.black54,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                _buildDifficultyRow(),
                const SizedBox(height: 28),
                const Text(
                  'CATEGORY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.black54,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                _buildCategoryGrid(),
                const SizedBox(height: 40),
                Center(child: _buildPlayButton()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _difficultyColor(String value) {
    switch (value) {
      case 'EASY':      return const Color(0xFF1D9358);
      case 'AVERAGE':   return const Color(0xFF046EB8);
      case 'DIFFICULT': return const Color(0xFFBD442E);
      default:          return const Color(0xFF1D9358);
    }
  }

  Widget _buildDifficultyRow() {
    return Row(
      children: difficultyLevels.map((difficulty) {
        final isSelected = _difficulty == difficulty['value'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () async {
                  try {
                    await AudioService().playClickSound();
                  } catch (e) {
                    debugPrint('Click sound error: $e');
                  }
                  setState(() {
                    _difficulty = difficulty['value']!;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? _difficultyColor(difficulty['value']!) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? _difficultyColor(difficulty['value']!) : Colors.black87,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(
                      color: _difficultyColor(difficulty['value']!).withValues(alpha: 0.5),
                      blurRadius: 8, offset: const Offset(0, 3),
                    )]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Text(
                        difficulty['display']!.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        difficulty['grid']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = _category == category['name'];

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () async {
              try {
                await AudioService().playClickSound();
              } catch (e) {
                debugPrint('Click sound error: $e');
              }
              setState(() {
                _category = category['name'];
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFFE6833A) : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: const Color(0xFFE6833A).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      category['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFE6833A),
                                Color(0xFFD4621A),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFE6833A).withValues(alpha: 0.7),
                            const Color(0xFFD4621A).withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            category['name']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayButton() {
    final canPlay = _category != null;

    return MouseRegion(
      cursor: canPlay ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: canPlay
            ? () async {
          try {
            await AudioService().playClickSound();
          } catch (e) {
            debugPrint('Click sound error: $e');
          }
          _startGame();
        }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 200,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: canPlay ? const Color(0xFFE6833A) : Colors.grey[300],
            borderRadius: BorderRadius.circular(50),
            boxShadow: canPlay
                ? [
              BoxShadow(
                color: const Color(0xFFE6833A).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
                : [],
          ),
          child: Text(
            'PLAY',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: canPlay ? Colors.white : Colors.grey[600],
              letterSpacing: 1.5,
            ),
          ),
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
              const SizedBox(height: 70),
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
                        color: Colors.white.withValues(alpha: 0.3),
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
                                      ? Colors.white.withValues(alpha: 0.2)
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
                        color: Colors.white.withValues(alpha: 0.2),
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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          decoration: const BoxDecoration(color: Colors.white),
          child: Row(
            children: [
              // Left — difficulty + category pill (mirrors memory match)
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6833A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_difficulty  ·  ${_category ?? ""}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),

              // Center — spacer for the floating timer circle
              Expanded(child: Container()),

              // Right — Moves + Pause button side by side
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Moves: $_moves",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE6833A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.pause_circle,
                          size: 42, color: Color(0xFFE6833A)),
                      onPressed: () async {
                        try {
                          await AudioService().playClickSound();
                        } catch (e) {
                          debugPrint('Click sound not found: $e');
                        }
                        _showPauseDialog();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 30,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE6833A),
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
}

// ── Full-page results screen (mirrors _MemoryMatchResultsPage) ──────────────
class _PuzzleResultsPage extends StatelessWidget {
  final String difficulty;
  final String category;
  final int starsEarned;
  final int yourTime;
  final int bestTime;
  final int personalBest;
  final int totalStars;
  final int moves;
  final bool isNewBestTime;
  final bool isNewPersonalRecord;
  final Map<String, dynamic>? newMilestone;
  final Map<String, dynamic>? currentTier;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const _PuzzleResultsPage({
    required this.difficulty,
    required this.category,
    required this.starsEarned,
    required this.yourTime,
    required this.bestTime,
    required this.personalBest,
    required this.totalStars,
    required this.moves,
    required this.isNewBestTime,
    required this.isNewPersonalRecord,
    required this.newMilestone,
    required this.currentTier,
    required this.onPlayAgain,
    required this.onExit,
  });

  Color _getDifficultyColor() {
    switch (difficulty.toUpperCase()) {
      case 'EASY':
        return const Color(0xFF2E7D32);
      case 'AVERAGE':
        return const Color(0xFF1976D2);
      case 'DIFFICULT':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFFE6833A);
    }
  }

  String _getResultMessage() {
    if (isNewBestTime) return 'You beat the best time!';
    if (isNewPersonalRecord) return 'You beat your personal best!';
    return 'Well done!';
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildStatBox(
      String value, String label, Color bgColor, Color textColor, bool showNewBadge) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  fontFamily: 'Poppins',
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  fontFamily: 'Poppins',
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          if (showNewBadge)
            Positioned(
              top: -8,
              right: -8,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1500),
                tween: Tween(begin: 1.0, end: 1.1),
                curve: Curves.easeInOut,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'NEW!',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF333333),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildSparkles() {
    sparkle(double top, double left, double bottom, double right) {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1500),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeInOut,
        builder: (context, v, child) => Opacity(
          opacity: v > 0.5 ? 1.0 - v : v * 2,
          child: Transform.scale(
            scale: v > 0.5 ? 2 - v * 2 : v * 2,
            child: child,
          ),
        ),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      );
    }

    return [
      Positioned(top: 20, left: 20, child: sparkle(20, 20, 0, 0)),
      Positioned(top: 40, right: 30, child: sparkle(40, 0, 0, 30)),
      Positioned(bottom: 40, right: 20, child: sparkle(0, 0, 40, 20)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final difficultyColor = _getDifficultyColor();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header bar — difficulty · category
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: difficultyColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${difficulty.toUpperCase()}  ·  $category',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 4),

                        // CONGRATULATIONS title — elastic pop-in
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) => Transform.scale(
                            scale: value,
                            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                          ),
                          child: Center(
                            child: Stack(
                              children: [
                                Text(
                                  'CONGRATULATIONS!',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 6
                                      ..color = const Color(0xFFC5A000),
                                    fontFamily: 'Poppins',
                                    letterSpacing: 2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const Text(
                                  'CONGRATULATIONS!',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFFDD000),
                                    fontFamily: 'Poppins',
                                    letterSpacing: 2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Bird Badge with bounce animation
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Transform.rotate(
                                angle: (1 - value) * -3.14,
                                child: Opacity(
                                  opacity: value.clamp(0.0, 1.0),
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: SizedBox(
                            width: 130,
                            height: 130,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ..._buildSparkles(),
                                Center(
                                  child: Image.asset(
                                    'assets/images-badges/whiz-achiever.png',
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Achievement message
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) =>
                              Opacity(opacity: value, child: child),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              fontSize: isNewPersonalRecord || isNewBestTime ? 22 : 20,
                              fontWeight: isNewPersonalRecord || isNewBestTime
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: isNewBestTime
                                  ? const Color(0xFFFF6B00)
                                  : isNewPersonalRecord
                                  ? const Color(0xFF4CAF50)
                                  : Colors.black87,
                              fontFamily: 'Poppins',
                              shadows: isNewPersonalRecord || isNewBestTime
                                  ? [
                                Shadow(
                                  color: (isNewBestTime
                                      ? const Color(0xFFFF6B00)
                                      : const Color(0xFF4CAF50))
                                      .withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ]
                                  : null,
                            ),
                            child: Text(_getResultMessage(), textAlign: TextAlign.center),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // PERFORMANCE STATS box
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.easeOut,
                          builder: (context, value, child) => Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          ),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 500),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFF0F0F0), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'PERFORMANCE STATS',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                    fontFamily: 'Poppins',
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Top row: Your Time · Best Time · Personal Best
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatBox(
                                        _formatTime(yourTime),
                                        'Your Time',
                                        const Color(0xFF90CAF9),
                                        const Color(0xFF0D47A1),
                                        false,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatBox(
                                        _formatTime(bestTime),
                                        'Best Time',
                                        const Color(0xFFFFCC80),
                                        const Color(0xFFE65100),
                                        isNewBestTime,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatBox(
                                        _formatTime(personalBest),
                                        'Personal Best',
                                        const Color(0xFFA5D6A7),
                                        const Color(0xFF1B5E20),
                                        isNewPersonalRecord,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Bottom row: Stars Earned · Total Stars
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatBox(
                                        '+$starsEarned',
                                        'Stars Earned',
                                        const Color(0xFFFFF59D),
                                        const Color(0xFFF57F17),
                                        false,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatBox(
                                        '$totalStars',
                                        'Total Stars',
                                        const Color(0xFFCE93D8),
                                        const Color(0xFF4A148C),
                                        false,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Milestone badge (if earned)
                        if (newMilestone != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFDD000).withValues(alpha: 0.2),
                                  const Color(0xFFFDD000).withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFDD000), width: 2),
                            ),
                            child: Column(
                              children: [
                                // ✅ Badge icon
                                const Icon(Icons.military_tech, color: Color(0xFFFDD000), size: 48),
                                const SizedBox(height: 4),
                                Text(
                                  '${newMilestone!['icon']} MILESTONE!',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFDD000),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  newMilestone!['prize'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // EXIT / PLAY AGAIN buttons
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) =>
                              Opacity(opacity: value, child: child),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: onExit,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: difficultyColor,
                                        side: BorderSide(color: difficultyColor, width: 3),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: const Text(
                                        'EXIT',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: onPlayAgain,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: difficultyColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        elevation: 4,
                                        shadowColor: difficultyColor.withValues(alpha: 0.3),
                                      ),
                                      child: const Text(
                                        'PLAY AGAIN',
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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