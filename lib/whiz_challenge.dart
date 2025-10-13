import 'package:flutter/material.dart';
import 'homepage.dart';

class WhizChallenge extends StatefulWidget {
  final UserProfile? profile;

  const WhizChallenge({super.key, this.profile});

  @override
  State<WhizChallenge> createState() => _WhizChallengeState();
}

class _WhizChallengeState extends State<WhizChallenge> {
  String? selectedCategory;
  String? selectedDifficulty;

  final List<Map<String, dynamic>> categories = [
    {
      "name": "Science",
      "imagePath": "assets/images-icons/science.png",
      "color": const Color(0xFF1D9358),
    },
    {
      "name": "Math",
      "imagePath": "assets/images-icons/math.png",
      "color": const Color(0xFF046EB8),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Top Navigation Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Image.asset(
                  "assets/images-logo/mainlogo.png",
                  width: 150,
                  height: 50,
                  fit: BoxFit.contain,
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTopNavButton("Home", Icons.home),
                        const SizedBox(width: 40),
                        _buildTopNavButton("Leaderboard", Icons.leaderboard),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF046EB8),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      "assets/images-avatars/${widget.profile?.avatar ?? 'Astronaut'}.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Yellow Header Bar
          Container(
            width: double.infinity,
            color: const Color(0xFFFFC527),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      "Whiz Challenge",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB36103),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side - Category selection with background
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Select Category",
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFC527),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Row(
                              children: categories.map((category) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: _buildCategoryCard(
                                    category["name"],
                                    category["imagePath"],
                                    category["color"],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 80),

                      // Right side - Difficulty level with background
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Difficulty Level",
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFC527),
                              ),
                            ),
                            const SizedBox(height: 40),
                            _buildDifficultyButton(
                              "EASY",
                              const Color(0xFF1D9358),
                            ),
                            const SizedBox(height: 20),
                            _buildDifficultyButton(
                              "AVERAGE",
                              const Color(0xFF046EB8),
                            ),
                            const SizedBox(height: 20),
                            _buildDifficultyButton(
                              "DIFFICULT",
                              const Color(0xFFBD442E),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Play Button at bottom
          Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: ElevatedButton(
              onPressed: selectedCategory != null && selectedDifficulty != null
                  ? () {
                      // Handle play action
                      print(
                        "Playing $selectedCategory at $selectedDifficulty level",
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEAAC00),
                disabledBackgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 80,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              child: const Text(
                "PLAY",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavButton(String label, IconData icon) {
    return InkWell(
      onTap: () {
        if (label == "Home") {
          Navigator.pop(context);
        } else if (label == "Leaderboard") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(
                profile: widget.profile ?? UserProfile(),
                initialTab: "Leaderboard",
              ),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.grey[700]),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.black)),
            ],
          ),
          const SizedBox(height: 3),
          Container(height: 3, width: 0, color: Colors.transparent),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String name, String imagePath, Color color) {
    final bool isSelected = selectedCategory == name;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = name;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 220,
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.05)
                      : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(17),
                    topRight: Radius.circular(17),
                  ),
                ),
                child: Center(
                  child: ColorFiltered(
                    colorFilter: isSelected
                        ? const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.multiply,
                          )
                        : const ColorFilter.matrix(<double>[
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ]),
                    child: Image.asset(
                      imagePath,
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(String label, Color color) {
    final bool isSelected = selectedDifficulty == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDifficulty = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 280,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : color,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
