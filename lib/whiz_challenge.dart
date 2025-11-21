import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'homepage.dart';
import 'quiz_game.dart';
import 'leaderboard.dart';

class WhizChallenge extends StatefulWidget {
  final UserProfile? profile;

  const WhizChallenge({super.key, this.profile});

  @override
  State<WhizChallenge> createState() => _WhizChallengeState();
}

class _WhizChallengeState extends State<WhizChallenge> {
  late UserProfile? _currentProfile;
  String? selectedCategory;
  String? selectedDifficulty;
  bool showMapView = false;
  String _selectedTab = "Challenge";

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
  }

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

  void _handlePlayButton() {
    if (selectedCategory != null && selectedDifficulty != null) {
      setState(() {
        showMapView = true;
      });
    }
  }

  void _handleBackToSelection() {
    setState(() {
      showMapView = false;
    });
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
              Image.asset(
                "assets/images-icons/sadlogout.png",
                width: 80,
                height: 80,
              ),
              const SizedBox(height: 15),
              const Text(
                "Logout Confirmation",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Are you sure you want to log out?",
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
                        backgroundColor: const Color(0xFFFDD000),
                        foregroundColor: const Color(0xFF816A03),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Logout",
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
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent;

    if (_selectedTab == "Leaderboard") {
      mainContent = const Leaderboard();
    } else {
      mainContent = Column(
        children: [
          _buildYellowHeader(),
          Expanded(
            child: showMapView ? _buildMapView() : _buildSelectionView(),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: _selectedTab == "Leaderboard"
          ? const Color(0xFF94D2FD)
          : Colors.grey.shade100,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(child: mainContent),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
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
                  child: _currentProfile?.avatar != null
                      ? Image.asset(_currentProfile!.avatar, fit: BoxFit.cover)
                      : const Icon(Icons.person, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavButton(String label, IconData icon) {
    final isActive =
        (label == "Home" && _selectedTab == "Challenge") ||
        (label == "Leaderboard" && _selectedTab == "Leaderboard");

    return InkWell(
      onTap: () {
        if (label == "Home") {
          if (_currentProfile != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    HomePage(profile: _currentProfile!, initialTab: "Home"),
              ),
            );
          } else {
            Navigator.pop(context);
          }
        } else if (label == "Leaderboard") {
          setState(() {
            _selectedTab = "Leaderboard";
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFFFFD13B) : Colors.grey[700],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFFFFD13B) : Colors.black,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: isActive ? 70 : 0,
            color: isActive ? const Color(0xFFFFD13B) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildYellowHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFC527),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              if (showMapView) {
                _handleBackToSelection();
              } else {
                if (_currentProfile != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomePage(
                        profile: _currentProfile!,
                        initialTab: "Home",
                      ),
                    ),
                  );
                } else {
                  Navigator.pop(context);
                }
              }
            },
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Whiz Challenge",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB36103),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSelectionView() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategorySection(),
                    const SizedBox(width: 80),
                    _buildDifficultySection(),
                  ],
                ),
              ),
            ),
          ),
        ),
        _buildPlayButton(),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Select Category",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFC527),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: categories.map((category) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
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
    );
  }

  Widget _buildDifficultySection() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Difficulty Level",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFC527),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 40),
          _buildDifficultyButton("EASY", const Color(0xFF1D9358)),
          const SizedBox(height: 20),
          _buildDifficultyButton("AVERAGE", const Color(0xFF046EB8)),
          const SizedBox(height: 20),
          _buildDifficultyButton("DIFFICULT", const Color(0xFFBD442E)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String name, String imagePath, Color color) {
    final bool isSelected = selectedCategory == name;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
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
                        width: 140,
                        height: 140,
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

  Widget _buildDifficultyButton(String label, Color color) {
    final bool isSelected = selectedDifficulty == label;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
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
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    final bool isEnabled =
        selectedCategory != null && selectedDifficulty != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 60),
      child: ElevatedButton(
        onPressed: isEnabled ? _handlePlayButton : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEAAC00),
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 18),
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
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    // Get difficulty color based on selected difficulty
    Color difficultyColor;
    Color backgroundColor;
    String badgeImage;
    bool showLeftArrow = true;
    bool showRightArrow = true;

    switch (selectedDifficulty) {
      case "EASY":
        difficultyColor = const Color(0xFF1D9358);
        backgroundColor = const Color(0xFFB8E6D5);
        badgeImage = "assets/images-badges/whiz-ready.png";
        showLeftArrow = false;
        break;
      case "AVERAGE":
        difficultyColor = const Color(0xFF046EB8);
        backgroundColor = const Color(0xFFB3D9F2);
        badgeImage = "assets/images-badges/whiz-happy.png";
        break;
      case "DIFFICULT":
        difficultyColor = const Color(0xFFBD442E);
        backgroundColor = const Color(0xFFE8C4B8);
        badgeImage = "assets/images-badges/whiz-achiever.png";
        showRightArrow = false;
        break;
      default:
        difficultyColor = const Color(0xFF1D9358);
        backgroundColor = const Color(0xFFB8E6D5);
        badgeImage = "assets/images-icons/placeholder.png";
    }

    return Container(
      color: backgroundColor,
      child: Stack(
        children: [
          if (showLeftArrow)
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 40),
                  color: Colors.black54,
                  onPressed: _switchToPreviousDifficulty,
                ),
              ),
            ),
          if (showRightArrow)
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 40),
                  color: Colors.black54,
                  onPressed: _switchToNextDifficulty,
                ),
              ),
            ),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              padding: const EdgeInsets.symmetric(
                horizontal: 100,
                vertical: 30,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedCategory?.toUpperCase() ?? "",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                      fontFamily: 'Poppins',
                      shadows: [
                        // Diagonals
                        Shadow(
                          color: difficultyColor,
                          offset: const Offset(-3.0, -3.0),
                          blurRadius: 0,
                        ),
                        Shadow(
                          color: difficultyColor,
                          offset: const Offset(3.0, -3.0),
                          blurRadius: 0,
                        ),
                        Shadow(
                          color: difficultyColor,
                          offset: const Offset(3.0, 3.0),
                          blurRadius: 0,
                        ),
                        Shadow(
                          color: difficultyColor,
                          offset: const Offset(-3.0, 3.0),
                          blurRadius: 0,
                        ),
                        // Cardinals (fill the gaps)
                        Shadow(
                          color: difficultyColor,
                          offset: const Offset(0, -3.0), // Straight UP
                          blurRadius: 0,
                        ),
                        Shadow(
                          color: difficultyColor,
                          offset: const Offset(0, 3.0), // Straight DOWN
                          blurRadius: 0,
                        ),
                        Shadow(
                          color: difficultyColor,
                          offset: const Offset(-3.0, 0), // Straight LEFT
                          blurRadius: 0,
                        ),
                        Shadow(
                          color: difficultyColor,
                          offset: const Offset(3.0, 0), // Straight RIGHT
                          blurRadius: 0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${selectedDifficulty ?? ""} LEVEL",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: difficultyColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                          painter: CurvedPathPainter(
                            color: difficultyColor,
                            difficulty: selectedDifficulty!,
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: _buildPathItems(
                              difficultyColor,
                              badgeImage,
                              constraints.maxWidth,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Get all the answers right to unlock badges!",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            category: selectedCategory!,
                            difficulty: selectedDifficulty!,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: difficultyColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 60,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      "PLAY",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPathItems(
    Color difficultyColor,
    String badgeImage,
    double width,
  ) {
    List<Map<String, dynamic>> positions = [];

    if (selectedDifficulty == "EASY") {
      positions = [
        {"x": 0.05, "y": 0.95, "type": "start"},
        {"x": 0.08, "y": 0.85, "number": 2},
        {"x": 0.11, "y": 0.75, "number": 3},
        {"x": 0.14, "y": 0.65, "number": 4},
        {"x": 0.17, "y": 0.55, "number": 5},
        {"x": 0.20, "y": 0.45, "number": 6},
        {"x": 0.23, "y": 0.35, "number": 7},
        {"x": 0.26, "y": 0.25, "number": 8},
        {"x": 0.29, "y": 0.15, "number": 9},
        {"x": 0.32, "y": 0.05, "number": 10},
        {"x": 0.20, "y": 0.02, "type": "badge"},
        {"x": 0.38, "y": 0.10, "number": 1},
        {"x": 0.44, "y": 0.20, "number": 2},
        {"x": 0.50, "y": 0.30, "number": 3},
        {"x": 0.56, "y": 0.40, "number": 4},
        {"x": 0.62, "y": 0.50, "number": 5},
        {"x": 0.68, "y": 0.60, "number": 6},
        {"x": 0.74, "y": 0.70, "number": 7},
        {"x": 0.80, "y": 0.80, "number": 8},
        {"x": 0.86, "y": 0.88, "number": 9},
        {"x": 0.92, "y": 0.95, "number": 10},
        {"x": 0.80, "y": 0.50, "type": "badge-empty"},
      ];
    } else if (selectedDifficulty == "AVERAGE") {
      positions = [
        {"x": 0.05, "y": 0.15, "type": "start"},
        {"x": 0.08, "y": 0.25, "number": 2},
        {"x": 0.11, "y": 0.35, "number": 3},
        {"x": 0.14, "y": 0.45, "number": 4},
        {"x": 0.17, "y": 0.55, "number": 5},
        {"x": 0.20, "y": 0.65, "number": 6},
        {"x": 0.23, "y": 0.75, "number": 7},
        {"x": 0.26, "y": 0.85, "number": 8},
        {"x": 0.29, "y": 0.93, "number": 9},
        {"x": 0.32, "y": 0.98, "number": 10},
        {"x": 0.24, "y": 0.72, "type": "badge"},
        {"x": 0.38, "y": 0.95, "number": 1},
        {"x": 0.44, "y": 0.87, "number": 2},
        {"x": 0.50, "y": 0.77, "number": 3},
        {"x": 0.56, "y": 0.65, "number": 4},
        {"x": 0.62, "y": 0.53, "number": 5},
        {"x": 0.68, "y": 0.40, "number": 6},
        {"x": 0.74, "y": 0.27, "number": 7},
        {"x": 0.80, "y": 0.15, "number": 8},
        {"x": 0.86, "y": 0.07, "number": 9},
        {"x": 0.92, "y": 0.02, "number": 10},
        {"x": 0.77, "y": 0.05, "type": "badge-empty"},
      ];
    } else {
      positions = [
        {"x": 0.05, "y": 0.95, "type": "start"},
        {"x": 0.08, "y": 0.85, "number": 2},
        {"x": 0.11, "y": 0.75, "number": 3},
        {"x": 0.14, "y": 0.65, "number": 4},
        {"x": 0.17, "y": 0.55, "number": 5},
        {"x": 0.20, "y": 0.45, "number": 6},
        {"x": 0.23, "y": 0.35, "number": 7},
        {"x": 0.26, "y": 0.25, "number": 8},
        {"x": 0.29, "y": 0.15, "number": 9},
        {"x": 0.32, "y": 0.05, "number": 10},
        {"x": 0.20, "y": 0.02, "type": "badge"},
        {"x": 0.38, "y": 0.08, "number": 1},
        {"x": 0.44, "y": 0.18, "number": 2},
        {"x": 0.50, "y": 0.30, "number": 3},
        {"x": 0.56, "y": 0.43, "number": 4},
        {"x": 0.62, "y": 0.56, "number": 5},
        {"x": 0.68, "y": 0.68, "number": 6},
        {"x": 0.74, "y": 0.78, "number": 7},
        {"x": 0.80, "y": 0.86, "number": 8},
        {"x": 0.86, "y": 0.92, "number": 9},
        {"x": 0.92, "y": 0.96, "number": 10},
        {"x": 0.77, "y": 0.50, "type": "badge-empty"},
      ];
    }

    List<Widget> widgets = [];

    for (var pos in positions) {
      double left = pos["x"] * width - 16;
      double top = pos["y"] * 300 - 16;

      if (pos["type"] == "start") {
        widgets.add(
          Positioned(
            left: left,
            top: top,
            child: _buildStartText(difficultyColor),
          ),
        );
      } else if (pos["type"] == "badge") {
        widgets.add(
          Positioned(
            left: left - 29,
            top: top - 29,
            child: _buildBadgeCircle(
              badgeImage: badgeImage,
              borderColor: difficultyColor,
              hasEarned: true,
            ),
          ),
        );
      } else if (pos["type"] == "badge-empty") {
        widgets.add(
          Positioned(
            left: left - 29,
            top: top - 29,
            child: _buildBadgeCircle(
              badgeImage: badgeImage,
              borderColor: difficultyColor,
              hasEarned: false,
            ),
          ),
        );
      } else {
        widgets.add(
          Positioned(
            left: left,
            top: top,
            child: _buildNumberCircle(
              pos["number"].toString(),
              difficultyColor,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  void _switchToPreviousDifficulty() {
    setState(() {
      if (selectedDifficulty == "AVERAGE") {
        selectedDifficulty = "EASY";
      } else if (selectedDifficulty == "DIFFICULT") {
        selectedDifficulty = "AVERAGE";
      }
    });
  }

  void _switchToNextDifficulty() {
    setState(() {
      if (selectedDifficulty == "EASY") {
        selectedDifficulty = "AVERAGE";
      } else if (selectedDifficulty == "AVERAGE") {
        selectedDifficulty = "DIFFICULT";
      }
    });
  }

  Widget _buildNumberCircle(String number, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade400,
        border: Border.all(color: Colors.grey.shade500, width: 2),
      ),
      child: Center(
        child: Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeCircle({
    required String badgeImage,
    required Color borderColor,
    required bool hasEarned,
  }) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: borderColor, width: 4),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: hasEarned
          ? ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  badgeImage,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.emoji_events,
                      color: borderColor,
                      size: 40,
                    );
                  },
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildStartText(Color color) {
    return Text(
      "START",
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 14,
        fontFamily: 'Poppins',
      ),
    );
  }
}

class CurvedPathPainter extends CustomPainter {
  final Color color;
  final String difficulty;

  CurvedPathPainter({required this.color, required this.difficulty});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (difficulty == "EASY") {
      path.moveTo(size.width * 0.05, size.height * 0.95);
      path.quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.40,
        size.width * 0.32,
        size.height * 0.05,
      );
      path.quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.05,
        size.width * 0.62,
        size.height * 0.50,
      );
      path.quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.90,
        size.width * 0.92,
        size.height * 0.95,
      );
    } else if (difficulty == "AVERAGE") {
      path.moveTo(size.width * 0.05, size.height * 0.15);
      path.quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.70,
        size.width * 0.32,
        size.height * 0.98,
      );
      path.quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.98,
        size.width * 0.62,
        size.height * 0.53,
      );
      path.quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.10,
        size.width * 0.92,
        size.height * 0.02,
      );
    } else {
      path.moveTo(size.width * 0.05, size.height * 0.95);
      path.quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.40,
        size.width * 0.32,
        size.height * 0.05,
      );
      path.quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.10,
        size.width * 0.62,
        size.height * 0.56,
      );
      path.quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.88,
        size.width * 0.92,
        size.height * 0.96,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
