import 'package:flutter/material.dart';

class QuizSetupDialog extends StatefulWidget {
  const QuizSetupDialog({super.key});

  @override
  State<QuizSetupDialog> createState() => _QuizSetupDialogState();
}

class _QuizSetupDialogState extends State<QuizSetupDialog> {
  String _selectedCategory = "General Knowledge";
  String _selectedDifficulty = "EASY";

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'General Knowledge',
      'icon': Icons.public,
      'color': Color(0xFF3498DB)
    },
    {'name': 'Science', 'icon': Icons.science, 'color': Color(0xFF9B59B6)},
    {'name': 'Mathematics', 'icon': Icons.calculate, 'color': Color(0xFFE67E22)},
    {'name': 'History', 'icon': Icons.history_edu, 'color': Color(0xFF95A5A6)},
    {'name': 'Geography', 'icon': Icons.map, 'color': Color(0xFF1ABC9C)},
    {
      'name': 'Technology',
      'icon': Icons.computer,
      'color': Color(0xFF34495E)
    },
  ];

  final List<Map<String, dynamic>> _difficulties = [
    {
      'name': 'EASY',
      'time': '15s',
      'color': Color(0xFF1D9358),
      'description': 'Perfect for beginners'
    },
    {
      'name': 'AVERAGE',
      'time': '20s',
      'color': Color(0xFF046EB8),
      'description': 'Moderate challenge'
    },
    {
      'name': 'DIFFICULT',
      'time': '25s',
      'color': Color(0xFFBD442E),
      'description': 'For quiz masters'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFFDD000),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Image.asset(
                    "assets/images-logo/whizchallenge.png",
                    width: 50,
                    height: 50,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.quiz, size: 50, color: Colors.white);
                    },
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Whiz Challenge",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF816A03),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          "Choose your quiz settings",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF816A03),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: const Color(0xFF816A03),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Selection
                    const Text(
                      "Select Category",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category['name'];
                        return _buildCategoryChip(
                          category['name'],
                          category['icon'],
                          category['color'],
                          isSelected,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 30),

                    // Difficulty Selection
                    const Text(
                      "Select Difficulty",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._difficulties.map((difficulty) {
                      final isSelected = _selectedDifficulty == difficulty['name'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildDifficultyCard(
                          difficulty['name'],
                          difficulty['time'],
                          difficulty['color'],
                          difficulty['description'],
                          isSelected,
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            // Footer with Start Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCategory,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          _selectedDifficulty,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getDifficultyColor(_selectedDifficulty),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, {
                        'category': _selectedCategory,
                        'difficulty': _selectedDifficulty,
                      });
                    },
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text(
                      "Start Quiz",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF046EB8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
      String name,
      IconData icon,
      Color color,
      bool isSelected,
      ) {
    return InkWell(
      onTap: () => setState(() => _selectedCategory = name),
      borderRadius: BorderRadius.circular(25),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: color,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyCard(
      String name,
      String time,
      Color color,
      String description,
      bool isSelected,
      ) {
    return InkWell(
      onTap: () => setState(() => _selectedDifficulty = name),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'EASY':
        return const Color(0xFF1D9358);
      case 'AVERAGE':
        return const Color(0xFF046EB8);
      case 'DIFFICULT':
        return const Color(0xFFBD442E);
      default:
        return const Color(0xFF1D9358);
    }
  }
}