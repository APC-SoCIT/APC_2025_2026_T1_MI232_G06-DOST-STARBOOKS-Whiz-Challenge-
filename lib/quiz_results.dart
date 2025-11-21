import 'package:flutter/material.dart';
import 'quiz_game.dart';

class QuizResultScreen extends StatelessWidget {
  final String category;
  final String difficulty;
  final int correctAnswers;
  final int incorrectAnswers;
  final int totalQuestions;
  final double averageTime;

  const QuizResultScreen({
    super.key,
    required this.category,
    required this.difficulty,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.totalQuestions,
    required this.averageTime,
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

  bool _isPerfectScore() {
    return correctAnswers == totalQuestions;
  }

  String _getResultImage() {
    if (_isPerfectScore()) {
      return "assets/images-badges/whiz-achiever.png";
    } else {
      return "assets/images-icons/sadlogout.png";
    }
  }

  String _getResultTitle() {
    if (_isPerfectScore()) {
      return "CONGRATULATIONS!";
    } else {
      return "TRY AGAIN!";
    }
  }

  String _getResultMessage() {
    if (_isPerfectScore()) {
      return "You've unlocked a new badge!";
    } else {
      return "Not quite there yet, but don't give up!";
    }
  }

  Color _getResultColor() {
    if (_isPerfectScore()) {
      return const Color(0xFFFDD000);
    } else {
      return const Color(0xFFBD442E);
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
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Result Title
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Stack(
                          children: [
                            // Outline/stroke effect
                            Text(
                              _getResultTitle(),
                              style: TextStyle(
                                fontSize: 55,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                letterSpacing: 1.5,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 6
                                  ..color = _isPerfectScore()
                                      ? const Color(0xFFAC8337)
                                      : const Color(0xFF631F13),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                            ),
                            // Filled text
                            Text(
                              _getResultTitle(),
                              style: TextStyle(
                                fontSize: 55,
                                fontWeight: FontWeight.bold,
                                color: _getResultColor(),
                                fontFamily: 'Poppins',
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Result Message
                      Text(
                        _getResultMessage(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      // Result Image/Character
                      Image.asset(
                        _getResultImage(),
                        width: 180,
                        height: 180,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            _isPerfectScore()
                                ? Icons.emoji_events
                                : Icons.sentiment_dissatisfied,
                            size: 80,
                            color: _getResultColor(),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Performance Stats Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC527),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "PERFORMANCE STATS",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontFamily: 'Poppins',
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatBox(
                                  "$correctAnswers",
                                  "Correct",
                                  const Color(0xFFACE2C8),
                                ),
                                _buildStatBox(
                                  "$incorrectAnswers",
                                  "Incorrect",
                                  const Color(0xFFFFB2A4),
                                ),
                                _buildStatBox(
                                  "${averageTime.toStringAsFixed(1)} s",
                                  "Avg time /\nQuestion",
                                  const Color(0xFFC2C5FF),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Exit Game / Home Button
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).popUntil(
                                  (route) =>
                                      route.isFirst ||
                                      route.settings.name == '/whiz_challenge',
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1D9358),
                                side: const BorderSide(
                                  color: Color(0xFF1D9358),
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Text(
                                _isPerfectScore() ? "Exit Game" : "Home",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Continue Playing / Retry Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (_isPerfectScore()) {
                                  Navigator.of(context).pop();
                                } else {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => QuizScreen(
                                        category: category,
                                        difficulty: difficulty,
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1D9358),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 3,
                              ),
                              child: Text(
                                _isPerfectScore()
                                    ? "Continue playing"
                                    : "Retry",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color difficultyColor) {
    return Container(
      width: double.infinity,
      color: difficultyColor,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Text(
            category.toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            difficulty.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label, Color backgroundColor) {
    return Container(
      width: 100,
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Poppins',
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
