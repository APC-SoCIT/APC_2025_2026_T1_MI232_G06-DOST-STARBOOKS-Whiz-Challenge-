import 'package:flutter/material.dart';
import 'quiz_game.dart';
import 'difficulty_settings_service.dart';
import 'audio_service.dart';  // Use AudioService instead of flame_audio
import 'game_tutorial_overlay.dart';

class WhizChallenge extends StatefulWidget {
  final String userId;
  final String userAvatar;
  final String username;
  final String? preselectedDifficulty;
  final String? preselectedCategory;

  const WhizChallenge({
    super.key,
    required this.userId,
    required this.userAvatar,
    required this.username,
    this.preselectedDifficulty,
    this.preselectedCategory,
  });

  @override
  State<WhizChallenge> createState() => _WhizChallengeState();
}

class _WhizChallengeState extends State<WhizChallenge> {
  final AudioService _audioService = AudioService();  // Add AudioService
  String selectedDifficulty = 'Easy';  // Changed from 'EASY' to match database
  String? selectedMainCategory;

  // Tutorial state
  bool _showGameTutorial = false;
  bool _checkingTutorialStatus = true;
  final String baseUrl = "http://localhost:8000";

  // Difficulty options
  final List<Map<String, String>> difficultyLevels = [
    {'value': 'Easy', 'display': 'Easy'},        // Changed from 'EASY'
    {'value': 'Average', 'display': 'Average'},  // Changed from 'AVERAGE'
    {'value': 'Difficult', 'display': 'Difficult'},  // Changed from 'DIFFICULT'
  ];

  // Simplified category definitions - Less detailed topics
  // Expanded topic lists per difficulty
  final Map<String, List<String>> mathSubcategories = {
    'Easy': [  // Changed from 'EASY'
      'Addition & Subtraction',
      'Multiplication',
      'Division',
      'Counting & Numbers',
      'Basic Shapes',
      'Comparing Numbers',
      'Number Patterns',
      'Telling Time',
    ],
    'Average': [  // Changed from 'AVERAGE'
      'Fractions & Decimals',
      'Algebra Basics',
      'Geometry',
      'Ratios & Proportions',
      'Percentages',
      'Area & Perimeter',
      'Integers',
      'Word Problems',
    ],
    'Difficult': [  // Changed from 'DIFFICULT'
      'Calculus',
      'Statistics & Probability',
      'Advanced Algebra',
      'Trigonometry',
      'Linear Equations',
      'Polynomials',
      'Logarithms',
      'Matrices',
    ],
  };

  final Map<String, List<String>> scienceSubcategories = {
    'Easy': [  // Changed from 'EASY'
      'Plants & Animals',
      'Human Body',
      'Weather & Seasons',
      'Day & Night',
      'Rocks & Soil',
      'Food Chains',
      'Simple Machines',
      'Senses',
    ],
    'Average': [  // Changed from 'AVERAGE'
      'Ecosystems',
      'Cells & Organisms',
      'Matter & States',
      'Forces & Motion',
      'Solar System',
      'Energy Types',
      'Water Cycle',
      'Photosynthesis',
    ],
    'Difficult': [  // Changed from 'DIFFICULT'
      'Molecular Biology',
      'Advanced Chemistry',
      'Quantum Physics',
      'Genetics & DNA',
      'Thermodynamics',
      'Electromagnetism',
      'Chemical Reactions',
      'Atomic Structure',
    ],
  };

  @override
  void initState() {
    super.initState();
    // Pre-load difficulty settings so quiz has them ready
    DifficultySettingsService.instance.load();

    // Initialize preselected values
    if (widget.preselectedDifficulty != null) {
      selectedDifficulty = widget.preselectedDifficulty!;
    }
    if (widget.preselectedCategory != null) {
      selectedMainCategory = widget.preselectedCategory;
    }

    // Handle music transition - stop homepage music, start quiz music
    _initializeMusic();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGameTutorialStatus();
    });
  }

  Future<void> _initializeMusic() async {
    try {
      // Smoothly transition from homepage music to quiz music
      await _audioService.playQuizMusic(fadeIn: true);
    } catch (e) {
      debugPrint('Error initializing music: $e');
    }
  }

  Future<void> _checkGameTutorialStatus() async {
    try {
      final shouldShow = await GameTutorialOverlay.shouldShowTutorial(
        widget.userId,
        'challenge',
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
          setState(() {
            _checkingTutorialStatus = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking tutorial status: $e');
      if (mounted) {
        setState(() {
          _checkingTutorialStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Play click sound
        await _audioService.playClickSound();

        // Stop quiz music and transition to homepage music
        await _audioService.stopMusic();
        await _audioService.playHomepageMusic(fadeIn: true);

        if (!mounted) return;
        Navigator.of(context).pop();
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.white,
            body: _checkingTutorialStatus
                ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFDD000)),
            )
                : Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _buildSelectionScreen(),
                ),
              ],
            ),
          ),

          // Game Tutorial Overlay
          if (_showGameTutorial)
            GameTutorialOverlay(
              userId: widget.userId,
              gameType: 'challenge',
              onComplete: () {
                setState(() => _showGameTutorial = false);
              },
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
              // Logo on the left
              Image.asset(
                "assets/images-logo/newhomepagelogo.png",
                width: 150,
                height: 50,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              // Avatar on the right
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _logoutDialog,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFDD000), width: 3),
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
            color: Color(0xFFFDD000),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              // Simple back arrow button with just <
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
                onPressed: () async {
                  try {
                    await _audioService.playClickSound();
                  } catch (e) {
                    debugPrint('Click sound not found: $e');
                  }

                  // Stop quiz music and transition to homepage music
                  await _audioService.stopMusic();
                  await _audioService.playHomepageMusic(fadeIn: true);

                  if (!mounted) return;
                  Navigator.pop(context);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Text(
                  "Whiz Challenge",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Difficulty label
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
                // Difficulty Row Selection
                _buildDifficultyRow(),
                const SizedBox(height: 28),

                // Category label
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

                // Math Category (Expandable)
                _buildExpandableCategorySection('Math', Icons.calculate),
                const SizedBox(height: 14),

                // Science Category (Expandable)
                _buildExpandableCategorySection('Science', Icons.science),
                const SizedBox(height: 40),

                // Play Button
                Center(child: _buildPlayButton()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyRow() {
    return Row(
      children: difficultyLevels.map((difficulty) {
        final isSelected = selectedDifficulty == difficulty['value'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () async {
                  try {
                    await _audioService.playClickSound();
                  } catch (e) {
                    debugPrint('Click sound error: $e');
                  }
                  setState(() {
                    selectedDifficulty = difficulty['value']!;
                    selectedMainCategory = null; // Reset category when difficulty changes
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFDD000) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFDD000) : Colors.black87,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: const Color(0xFFFDD000).withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                        : [],
                  ),
                  child: Text(
                    difficulty['display']!.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpandableCategorySection(String category, IconData icon) {
    final isExpanded = selectedMainCategory?.toLowerCase() == category.toLowerCase();
    final topics = category.toLowerCase() == 'math'
        ? mathSubcategories[selectedDifficulty] ?? []
        : scienceSubcategories[selectedDifficulty] ?? [];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          try {
            await _audioService.playClickSound();
          } catch (e) {
            debugPrint('Click sound error: $e');
          }
          setState(() {
            if (isExpanded) {
              selectedMainCategory = null;
            } else {
              selectedMainCategory = category.toUpperCase();
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExpanded ? const Color(0xFFFDD000) : Colors.black87,
              width: 2,
            ),
            boxShadow: isExpanded
                ? [
              BoxShadow(
                color: const Color(0xFFFDD000).withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              children: [
                // ── Yellow header ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  color: isExpanded ? const Color(0xFFFDD000) : Colors.white,
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: Colors.black87, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isExpanded ? Icons.remove : Icons.add,
                          color: Colors.black87,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── White topics body (animated) ──
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity, height: 0),
                  secondChild: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOPICS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.black45,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: topics.map((topic) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                  color: Colors.grey[300]!, width: 1.5),
                            ),
                            child: Text(
                              topic,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    final isEnabled = selectedMainCategory != null;

    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: isEnabled
            ? () async {
          try {
            await _audioService.playClickSound();
          } catch (e) {
            debugPrint('Click sound error: $e');
          }
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(
                userId: widget.userId,
                category: selectedMainCategory!,
                difficulty: selectedDifficulty,
              ),
            ),
          );
        }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
          decoration: BoxDecoration(
            gradient: isEnabled
                ? const LinearGradient(
              colors: [Color(0xFFFDD000), Color(0xFFFFC700)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: isEnabled ? null : Colors.grey[300],
            borderRadius: BorderRadius.circular(30),
            boxShadow: isEnabled
                ? [
              const BoxShadow(
                color: Color(0x40FDD000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ]
                : [],
          ),
          child: Text(
            'PLAY',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isEnabled ? Colors.black87 : Colors.grey[600],
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  void _logoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  "assets/images-icons/sadlogout.png",
                  width: 80,
                  height: 80,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.exit_to_app, size: 80, color: Color(0xFFFDD000));
                  },
                ),
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
                  "Are you sure you want to exit?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                            color: Color(0xFFFDD000),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "No",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Color(0xFFFDD000),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFDD000),
                          foregroundColor: const Color(0xFF816A03),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
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
                )
              ],
            ),
          ),
        );
      },
    );
  }
}