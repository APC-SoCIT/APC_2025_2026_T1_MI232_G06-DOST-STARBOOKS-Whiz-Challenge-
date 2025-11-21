import 'package:flutter/material.dart';
import 'dart:async';
import 'quiz_questions.dart';
import 'quiz_results.dart';

class QuizScreen extends StatefulWidget {
  final String category;
  final String difficulty;

  const QuizScreen({
    super.key,
    required this.category,
    required this.difficulty,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Question> questions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  int correctAnswers = 0;
  int incorrectAnswers = 0;
  List<double> questionTimes = [];

  Timer? _timer;
  int _secondsRemaining = 15;
  bool _showFeedback = false;
  bool _isCorrect = false;
  String? _selectedAnswer;
  bool _isAnswerLocked = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _startTimer();
  }

  void _loadQuestions() {
    questions = QuizData.getQuestions(widget.category, widget.difficulty);
  }

  void _startTimer() {
    _secondsRemaining = 15;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _handleTimeout();
          }
        });
      }
    });
  }

  void _resumeTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _handleTimeout();
          }
        });
      }
    });
  }

  void _handleTimeout() {
    if (_isAnswerLocked) return;

    _timer?.cancel();
    _isAnswerLocked = true;

    setState(() {
      incorrectAnswers++;
      questionTimes.add(15.0);
      _showFeedback = true;
      _isCorrect = false;
      _selectedAnswer = null;
    });
  }

  void _handleAnswer(String answer) {
    if (_showFeedback || _isAnswerLocked) return;

    _timer?.cancel();
    _isAnswerLocked = true;

    final timeTaken = 15 - _secondsRemaining;
    questionTimes.add(timeTaken.toDouble());

    final isCorrect = answer == questions[currentQuestionIndex].correctAnswer;

    setState(() {
      _selectedAnswer = answer;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showFeedback = true;
          _isCorrect = isCorrect;

          if (isCorrect) {
            correctAnswers++;
            score++;
          } else {
            incorrectAnswers++;
          }
        });
      }
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        _showFeedback = false;
        _isCorrect = false;
        _selectedAnswer = null;
        _isAnswerLocked = false;
      });
      _startTimer();
    } else {
      _navigateToResults();
    }
  }

  void _navigateToResults() {
    _timer?.cancel();

    final avgTime = questionTimes.isNotEmpty
        ? questionTimes.reduce((a, b) => a + b) / questionTimes.length
        : 0.0;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          category: widget.category,
          difficulty: widget.difficulty,
          correctAnswers: correctAnswers,
          incorrectAnswers: incorrectAnswers,
          totalQuestions: questions.length,
          averageTime: avgTime,
        ),
      ),
    );
  }

  Future<void> _showExitDialog() async {
    // Pause the timer
    _timer?.cancel();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF39C12),
                size: 60,
              ),
              const SizedBox(height: 15),
              const Text(
                "Exit Game?",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Are you sure you want to exit? Your progress will be lost.",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: Color(0xFF046EB8),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Color(0xFF046EB8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE74C3C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Exit",
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
      Navigator.pop(context);
    } else if (mounted && !_showFeedback && !_isAnswerLocked) {
      // Resume the timer if user cancels and game is still active (without resetting seconds)
      _resumeTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _getDifficultyColor() {
    switch (widget.difficulty.toUpperCase()) {
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

  // Get button colors based on answer index
  Color _getButtonColor(int index) {
    final colors = [
      const Color(0xFF046EB8),
      const Color(0xFFF39C12),
      const Color(0xFFE67E22),
      const Color(0xFF9B59B6),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final question = questions[currentQuestionIndex];
    final difficultyColor = _getDifficultyColor();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(difficultyColor),
          Expanded(
            child: _showFeedback
                ? _buildFeedbackView(difficultyColor)
                : _buildQuestionView(question, difficultyColor),
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
            widget.category.toUpperCase(),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.difficulty.toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
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

  Widget _buildQuestionView(Question question, Color difficultyColor) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Exit Game Button
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _showExitDialog,
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.black87,
                    size: 18,
                  ),
                  label: const Text(
                    'Exit Game',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 4,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Timer Circle with Animation
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                tween: Tween<double>(
                  begin: _secondsRemaining / 15,
                  end: _secondsRemaining / 15,
                ),
                builder: (context, value, child) {
                  return SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circle
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        // Animated progress ring
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 8,
                            backgroundColor: const Color(0xFFE0E0E0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              difficultyColor,
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        // Timer number
                        Text(
                          "$_secondsRemaining",
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: difficultyColor,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Question Counter and Score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Question: ${currentQuestionIndex + 1} of ${questions.length}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    "Score: $score",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // Question Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: difficultyColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: difficultyColor, width: 2),
                ),
                child: Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              // Answer Options - Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.5,
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

  Widget _buildAnswerButton(String answer, int index) {
    final buttonColor = _getButtonColor(index);
    final isSelected = _selectedAnswer == answer && _isAnswerLocked;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _handleAnswer(answer),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? buttonColor : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: buttonColor, width: isSelected ? 4 : 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackView(Color difficultyColor) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Feedback Title
              Text(
                _isCorrect ? "CORRECT ANSWER!" : "WRONG ANSWER!",
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: _isCorrect
                      ? const Color(0xFF1D9358)
                      : const Color(0xFFE74C3C),
                  fontFamily: 'Poppins',
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // Next Question Button
              ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF046EB8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Next Question",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Answer Box with Light Bulb Icon
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: difficultyColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: difficultyColor, width: 2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Image.asset(
                        "assets/images-icons/lightbulb.png",
                        width: 40,
                        height: 40,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.lightbulb,
                            color: Color(0xFFFFC107),
                            size: 40,
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            questions[currentQuestionIndex].question,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                color: Colors.black87,
                              ),
                              children: [
                                const TextSpan(
                                  text: "Answer: ",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                TextSpan(
                                  text: questions[currentQuestionIndex]
                                      .correctAnswer,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
