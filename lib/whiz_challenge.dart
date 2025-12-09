import 'package:flutter/material.dart';
import 'quiz_game.dart';

class WhizChallenge extends StatefulWidget {
  final String userId;

  const WhizChallenge({
    super.key,
    required this.userId,
  });

  @override
  State<WhizChallenge> createState() => _WhizChallengeState();
}

class _WhizChallengeState extends State<WhizChallenge> {
  String selectedCategory = 'Science';
  String selectedDifficulty = 'Easy';

  // Map of levels - can be expanded
  final Map<String, List<Map<String, dynamic>>> levelMaps = {
    'Science-Easy': [
      {'level': 1, 'unlocked': true},
      {'level': 2, 'unlocked': false},
      {'level': 3, 'unlocked': false},
      {'level': 4, 'unlocked': false},
      {'level': 5, 'unlocked': false},
      {'level': 6, 'unlocked': false},
      {'level': 7, 'unlocked': false},
      {'level': 8, 'unlocked': false},
      {'level': 9, 'unlocked': false},
      {'level': 10, 'unlocked': false},
    ],
    'Science-Average': [
      {'level': 1, 'unlocked': true},
      {'level': 2, 'unlocked': false},
      {'level': 3, 'unlocked': false},
      {'level': 4, 'unlocked': false},
      {'level': 5, 'unlocked': false},
      {'level': 6, 'unlocked': false},
      {'level': 7, 'unlocked': false},
      {'level': 8, 'unlocked': false},
      {'level': 9, 'unlocked': false},
      {'level': 10, 'unlocked': false},
    ],
    'Science-Difficult': [
      {'level': 1, 'unlocked': true},
      {'level': 2, 'unlocked': false},
      {'level': 3, 'unlocked': false},
      {'level': 4, 'unlocked': false},
      {'level': 5, 'unlocked': false},
      {'level': 6, 'unlocked': false},
      {'level': 7, 'unlocked': false},
      {'level': 8, 'unlocked': false},
      {'level': 9, 'unlocked': false},
      {'level': 10, 'unlocked': false},
    ],
    'Math-Easy': [
      {'level': 1, 'unlocked': true},
      {'level': 2, 'unlocked': false},
      {'level': 3, 'unlocked': false},
      {'level': 4, 'unlocked': false},
      {'level': 5, 'unlocked': false},
      {'level': 6, 'unlocked': false},
      {'level': 7, 'unlocked': false},
      {'level': 8, 'unlocked': false},
      {'level': 9, 'unlocked': false},
      {'level': 10, 'unlocked': false},
    ],
    'Math-Average': [
      {'level': 1, 'unlocked': true},
      {'level': 2, 'unlocked': false},
      {'level': 3, 'unlocked': false},
      {'level': 4, 'unlocked': false},
      {'level': 5, 'unlocked': false},
      {'level': 6, 'unlocked': false},
      {'level': 7, 'unlocked': false},
      {'level': 8, 'unlocked': false},
      {'level': 9, 'unlocked': false},
      {'level': 10, 'unlocked': false},
    ],
    'Math-Difficult': [
      {'level': 1, 'unlocked': true},
      {'level': 2, 'unlocked': false},
      {'level': 3, 'unlocked': false},
      {'level': 4, 'unlocked': false},
      {'level': 5, 'unlocked': false},
      {'level': 6, 'unlocked': false},
      {'level': 7, 'unlocked': false},
      {'level': 8, 'unlocked': false},
      {'level': 9, 'unlocked': false},
      {'level': 10, 'unlocked': false},
    ],
  };

  String get currentMapKey => '$selectedCategory-$selectedDifficulty';

  List<Map<String, dynamic>> get currentLevels => levelMaps[currentMapKey] ?? [];

  Color get difficultyColor {
    switch (selectedDifficulty) {
      case 'Easy':
        return const Color(0xFF1D9358);
      case 'Average':
        return const Color(0xFF046EB8);
      case 'Difficult':
        return const Color(0xFFBD442E);
      default:
        return const Color(0xFF1D9358);
    }
  }

  String get backgroundImage {
    if (selectedCategory == 'Science') {
      switch (selectedDifficulty) {
        case 'Easy':
          return 'assets/images/science-easy-bg.png'; // Your green science bg
        case 'Average':
          return 'assets/images/science-average-bg.png'; // Your blue science bg
        case 'Difficult':
          return 'assets/images/science-difficult-bg.png'; // Your volcano science bg
      }
    } else {
      // Math backgrounds
      switch (selectedDifficulty) {
        case 'Easy':
          return 'assets/images/math-easy-bg.png';
        case 'Average':
          return 'assets/images/math-average-bg.png';
        case 'Difficult':
          return 'assets/images/math-difficult-bg.png';
      }
    }
    return 'assets/images/science-easy-bg.png';
  }

  void _selectCategoryAndDifficulty() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Category & Difficulty',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),

              // Category Selection
              const Text(
                'Select Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCategoryButton('Science'),
                  const SizedBox(width: 15),
                  _buildCategoryButton('Math'),
                ],
              ),

              const SizedBox(height: 25),

              // Difficulty Selection
              const Text(
                'Difficulty Level',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  _buildDifficultyButton('Easy', const Color(0xFF1D9358)),
                  const SizedBox(height: 10),
                  _buildDifficultyButton('Average', const Color(0xFF046EB8)),
                  const SizedBox(height: 10),
                  _buildDifficultyButton('Difficult', const Color(0xFFBD442E)),
                ],
              ),

              const SizedBox(height: 25),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDD000),
                  foregroundColor: const Color(0xFF915701),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String category) {
    final isSelected = selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = category),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF046EB8) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF046EB8) : Colors.grey,
            width: 2,
          ),
        ),
        child: Text(
          category,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(String difficulty, Color color) {
    final isSelected = selectedDifficulty == difficulty;
    return GestureDetector(
      onTap: () => setState(() => selectedDifficulty = difficulty),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(
          difficulty.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : color,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  void _playLevel(int level) async {
    final isUnlocked = currentLevels[level - 1]['unlocked'] ?? false;

    if (!isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete previous level to unlock this!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to quiz
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          category: selectedCategory,
          difficulty: selectedDifficulty,
          userId: widget.userId,
          participationType: 'Whiz Challenge',
        ),
      ),
    );

    // If completed successfully, unlock next level
    if (result == true && mounted) {
      setState(() {
        if (level < currentLevels.length) {
          currentLevels[level]['unlocked'] = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                color: difficultyColor,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Spacer(),
                    Column(
                      children: [
                        Text(
                          selectedCategory.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          '${selectedDifficulty.toUpperCase()} LEVEL',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _selectCategoryAndDifficulty,
                      icon: const Icon(Icons.settings, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Level Map
              Expanded(
                child: Stack(
                  children: [
                    // Level circles positioned on the map
                    Positioned(
                      left: 40,
                      bottom: 50,
                      child: _buildLevelCircle(1),
                    ),
                    Positioned(
                      left: 60,
                      bottom: 120,
                      child: _buildLevelCircle(2),
                    ),
                    Positioned(
                      left: 90,
                      bottom: 180,
                      child: _buildLevelCircle(3),
                    ),
                    Positioned(
                      left: 130,
                      bottom: 230,
                      child: _buildLevelCircle(4),
                    ),
                    Positioned(
                      left: 180,
                      bottom: 260,
                      child: _buildLevelCircle(5),
                    ),
                    Positioned(
                      right: 180,
                      bottom: 280,
                      child: _buildLevelCircle(6),
                    ),
                    Positioned(
                      right: 120,
                      bottom: 240,
                      child: _buildLevelCircle(7),
                    ),
                    Positioned(
                      right: 80,
                      bottom: 180,
                      child: _buildLevelCircle(8),
                    ),
                    Positioned(
                      right: 60,
                      bottom: 120,
                      child: _buildLevelCircle(9),
                    ),
                    Positioned(
                      right: 50,
                      bottom: 50,
                      child: _buildLevelCircle(10),
                    ),

                    // Instructions
                    Positioned(
                      bottom: 150,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Get all the answers right to unlock badges!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCircle(int level) {
    final isUnlocked = currentLevels[level - 1]['unlocked'] ?? false;

    return GestureDetector(
      onTap: () => _playLevel(level),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isUnlocked ? difficultyColor : Colors.grey,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isUnlocked
              ? Text(
            '$level',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          )
              : const Icon(
            Icons.lock,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}