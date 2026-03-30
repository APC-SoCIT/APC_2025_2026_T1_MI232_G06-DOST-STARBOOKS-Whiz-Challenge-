import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'login.dart';
import 'edit_profile.dart';
import 'player_badges.dart';
import 'whiz_battle.dart';
import 'whiz_challenge.dart';
import 'whiz_puzzle.dart';
import 'whiz_memory_match.dart';
import 'leaderboard.dart';

import 'tutorial_overlay.dart';
import 'loading_page.dart';  // ✅ ADDED: Loading screen
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_service.dart';  // ✅ ADDED: Audio service for music continuity
import 'session_manager.dart'; // ✅ ADDED: Session persistence (skip splash on refresh)

// ✅ USER PROFILE MODEL
class UserProfile {
  String id;
  String username;
  String school;
  String age;
  String category;
  String? studentCategory;
  String sex;
  String region;
  String province;
  String city;
  String avatar;
  int stars; // ← ADD THIS LINE

  UserProfile({
    required this.id,
    required this.username,
    required this.school,
    required this.age,
    required this.category,
    this.studentCategory,
    required this.sex,
    required this.region,
    required this.province,
    required this.city,
    required this.avatar,
    this.stars = 0, // ← ADD THIS LINE
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    var idValue = json['id'] ?? json['_id'] ?? '';
    if (idValue is Map && idValue.containsKey('\$oid')) {
      idValue = idValue['\$oid'];
    }

    return UserProfile(
      id: idValue.toString(),
      username: json['username'] ?? '',
      school: json['school'] ?? '',
      age: json['age']?.toString() ?? '',
      category: json['category'] ?? '',
      studentCategory: json['student_category'],
      sex: json['sex'] ?? '',
      region: json['region']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      avatar: json['avatar'] ?? "assets/images-avatars/Adventurer.png",
      stars: json['stars'] ?? 0, // ← ADD THIS LINE
    );
  }

  UserProfile copyWith({
    String? username,
    String? school,
    String? age,
    String? category,
    String? studentCategory,
    String? sex,
    String? region,
    String? province,
    String? city,
    String? avatar,
    int? stars, // ← ADD THIS LINE
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      school: school ?? this.school,
      age: age ?? this.age,
      category: category ?? this.category,
      studentCategory: studentCategory ?? this.studentCategory,
      sex: sex ?? this.sex,
      region: region ?? this.region,
      province: province ?? this.province,
      city: city ?? this.city,
      avatar: avatar ?? this.avatar,
      stars: stars ?? this.stars, // ← ADD THIS LINE
    );
  }
}

// ✅ HOME PAGE
class HomePage extends StatefulWidget {
  final UserProfile profile;
  final String initialTab;
  final bool isNewUser; // Added for tutorial trigger

  const HomePage({
    super.key,
    required this.profile,
    this.initialTab = "Home",
    this.isNewUser = false, // Default to false for existing users
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final GlobalKey _profileCardKey = GlobalKey();
  final GlobalKey _memoryMatchKey = GlobalKey();
  final GlobalKey _whizChallengeKey = GlobalKey();
  final GlobalKey _whizBattleKey = GlobalKey();
  final GlobalKey _whizPuzzleKey = GlobalKey();
  final GlobalKey _profileAvatarKey = GlobalKey();
  final GlobalKey _starCountKey = GlobalKey();
  final GlobalKey _badgesButtonKey = GlobalKey();
  final GlobalKey _leaderboardKey = GlobalKey();

  late UserProfile _currentProfile;
  late String _selectedTab;
  bool _loadingProfile = true;
  final String baseUrl = "http://localhost:8000";
  bool _showStarTooltip = false;
  bool _showTutorial = false;  // ← ADD THIS LINE

  late AnimationController _flashController;
  bool _isFlashing = false;
  final AudioService _audioService = AudioService();  // ✅ ADDED: Audio service instance

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
    _selectedTab = widget.initialTab;

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // ✅ UPDATED: Ensure homepage music continues playing (no fade-in since already playing from splash)
    _audioService.playHomepageMusic(fadeIn: false);

    // THIS IS THE KEY CHANGE - Load data first, then check tutorial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserWithLocationNames().then((_) {
        if (mounted) {
          // ✅ Session already saved in login.dart on successful login.
          // Re-save here to keep stored profile data fresh (stars, avatar, etc.)
          SessionManager.saveSession(_currentProfile);
          _checkAndShowTutorial();
        }
      });
    });
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  Future<void> _checkAndShowTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tutorialCompleted = prefs.getBool('main_tutorial_completed_${_currentProfile.id}') ?? false;

      if (tutorialCompleted) {
        debugPrint('Tutorial already completed - skipping');
        return;
      }

      // Show tutorial for any user who hasn't completed it yet
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          setState(() => _showTutorial = true);
        }
      }
    } catch (e) {
      debugPrint('Error checking tutorial status: $e');
    }
  }

  Future<void> _loadUserWithLocationNames({bool loadLocationData = true}) async {
    setState(() => _loadingProfile = true);
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/homepage/${_currentProfile.id}"));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final user = data['user'];
          if (mounted) {
            setState(() {
              if (loadLocationData) {
                // Load everything including location data (initial load or after profile edit)
                _currentProfile = _currentProfile.copyWith(
                  region: user['region'] ?? '',
                  province: user['province'] ?? '',
                  city: user['city'] ?? '',
                  stars: user['stars'] ?? 0,
                  category: user['category'] ?? _currentProfile.category,
                  studentCategory: user['student_category'],
                );
              } else {
                // Only update stars (after returning from games)
                _currentProfile = _currentProfile.copyWith(
                  stars: user['stars'] ?? 0,
                );
              }
              _loadingProfile = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => _loadingProfile = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  // Lightweight method to update only stars without showing loading screen
  Future<void> _updateStarsOnly() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/homepage/${_currentProfile.id}"));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && mounted) {
          final user = data['user'];
          setState(() {
            _currentProfile = _currentProfile.copyWith(
              stars: user['stars'] ?? _currentProfile.stars,
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating stars: $e');
      // Silently fail - not critical
    }
  }

  String get regionName => _currentProfile.region.isNotEmpty ? _currentProfile.region : "Unknown Region";
  String get provinceName => _currentProfile.province.isNotEmpty ? _currentProfile.province : "Unknown Province";
  String get cityName => _currentProfile.city.isNotEmpty ? _currentProfile.city : "Unknown City";

  Future<void> _logout() async {
    try {
      // Show loading screen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const LoadingPage(),
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // ✅ Clear session FIRST — so if the user refreshes after logout
      // they see SplashScreen (no session = splash, by design in main.dart)
      await SessionManager.clearSession();

      // Clear any other runtime prefs (games_played, rating prompts, etc.)
      // but keep tutorial completion flags so they survive logout
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys().toList();
      for (final key in allKeys) {
        if (key.startsWith('main_tutorial_completed_') ||
            key.startsWith('game_tutorial_completed_') ||
            key.startsWith('session_')) {
          continue; // preserve these
        }
        await prefs.remove(key);
      }

      // Navigate to login screen (in-app logout goes to Login, not Splash)
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error logging out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editProfile() async {
    final updatedProfile = await showDialog<UserProfile>(
      context: context,
      builder: (_) => EditProfileDialog(profile: _currentProfile),
    );
    if (updatedProfile != null && mounted) {
      setState(() => _currentProfile = updatedProfile);
      // Reload location data since user may have changed their address
      await _loadUserWithLocationNames(loadLocationData: true);
    }
  }


  // ✅ NEW: Show rating dialog
  Future<void> _showRatingDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _RatingDialog(
          userId: _currentProfile.id,
          baseUrl: baseUrl,
          onRatingSubmitted: _markUserAsRated,
        );
      },
    );
  }

  // ✅ NEW: Show profile menu with Logout and Rate options
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => _SettingsDialog(
        userId: _currentProfile.id,
        baseUrl: baseUrl,
        onLogout: _logout,
        onEditProfile: _editProfile, // ✅ NEW
      ),
    );
  }

  Widget _buildTopNavButton(String label, IconData icon) {
    final isActive = _selectedTab == label;
    return InkWell(
      onTap: () async {
        try {
          await _audioService.playClickSound();
        } catch (e) {
          debugPrint('Click sound not found: $e');
        }
        setState(() => _selectedTab = label);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: isActive ? const Color(0xFFFFD13B) : Colors.grey[700]),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  color: isActive ? const Color(0xFFFFD13B) : Colors.black,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                )),
          ]),
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

  Future<void> _triggerFlashAndNavigate(Widget page) async {
    if (_isFlashing) return;
    setState(() => _isFlashing = true);

    await _flashController.forward();

    if (mounted) {
      // ✅ Show loading page before navigating to game
      LoadingHelper.showLoadingPage(context, message: 'Loading game...');

      // Give proper time for loading animation (1.5 seconds for smooth experience)
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        LoadingHelper.hideLoading(context); // Hide loading page

        // Small delay to ensure loading is fully hidden before navigation
        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          await Navigator.push(
            context,
            PageRouteBuilder(
              opaque: true,
              barrierColor: const Color(0xFF87CEEB), // Prevent white flash during transition
              pageBuilder: (_, _, _) => page,
              transitionDuration: const Duration(milliseconds: 600),
              transitionsBuilder: (_, animation, _, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );

          // Update stars silently without loading screen (games may have changed star count)
          if (mounted) {
            _updateStarsOnly();
            _incrementGameCounterAndCheckRating(); // Check if we should prompt for rating
          }
        }
      }
    }

    if (mounted) {
      await _flashController.reverse();
      setState(() => _isFlashing = false);
    }
  }

  Color _getStarColor() {
    if (_currentProfile.stars >= 1000) return const Color(0xFFB9F2FF); // Diamond (light blue)
    if (_currentProfile.stars >= 500) return const Color(0xFFE5E4E2); // Platinum (silver-white)
    if (_currentProfile.stars >= 250) return const Color(0xFFFFD700); // Gold
    if (_currentProfile.stars >= 100) return const Color(0xFFC0C0C0); // Silver
    if (_currentProfile.stars >= 50) return const Color(0xFFCD7F32); // Bronze
    return Colors.white; // Default white
  }

  // ✅ Track games played and prompt for rating strategically
  Future<void> _incrementGameCounterAndCheckRating() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = 'games_played_${_currentProfile.id}';
      final hasRatedKey = 'has_rated_${_currentProfile.id}';
      final lastPromptKey = 'last_rating_prompt_${_currentProfile.id}';

      final gamesPlayed = (prefs.getInt(userKey) ?? 0) + 1;
      final hasRated = prefs.getBool(hasRatedKey) ?? false;
      final lastPromptTime = prefs.getInt(lastPromptKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final dayInMs = 86400000; // 24 hours in milliseconds

      await prefs.setInt(userKey, gamesPlayed);

      // Show rating prompt if:
      // 1. User has played 5, 15, or 30 games
      // 2. User hasn't rated yet
      // 3. Haven't prompted in the last 3 days (to avoid annoyance)
      final shouldPrompt = !hasRated &&
          (now - lastPromptTime) > (dayInMs * 3) &&
          (gamesPlayed == 5 || gamesPlayed == 15 || gamesPlayed == 30);

      if (shouldPrompt && mounted) {
        await prefs.setInt(lastPromptKey, now);

        // Wait a moment for smooth transition
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          _showRatingDialog();
        }
      }
    } catch (e) {
      debugPrint('Error checking rating prompt: $e');
    }
  }

  // ✅ Mark user as having rated (called after successful rating submission)
  Future<void> _markUserAsRated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_rated_${_currentProfile.id}', true);
    } catch (e) {
      debugPrint('Error marking user as rated: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainContent = _selectedTab == "Leaderboard"
        ? Leaderboard(
      currentUserId: _currentProfile.id,
      userAvatar: _currentProfile.avatar,
      username: _currentProfile.username,
    )
        : _buildHomeContent();

    return Stack(
      children: [
        Stack(
          children: [
            Scaffold(
              backgroundColor: const Color(0xFF046EB8),
              body: _loadingProfile
                  ? const LoadingPage(message: 'Loading your profile...')
                  : Column(children: [
                _buildTopBar(),
                Expanded(child: mainContent),
              ]),
            ),
            AnimatedBuilder(
              animation: _flashController,
              builder: (context, child) {
                return IgnorePointer(
                  ignoring: true,
                  child: Opacity(
                    opacity: _flashController.value,
                    child: Container(color: const Color(0xFF87CEEB)), // Changed from white to sky blue
                  ),
                );
              },
            ),
          ],
        ),
        // ← ADD TUTORIAL OVERLAY HERE
        if (_showTutorial)
          TutorialOverlay(
            userId: _currentProfile.id,
            onComplete: () async {
              if (mounted) {
                setState(() => _showTutorial = false);
              }
            },
            elementKeys: {
              'profile_avatar': _profileAvatarKey,
              'star_count': _starCountKey,
              'badges_button': _badgesButtonKey,
              'memory_match': _memoryMatchKey,
              'whiz_challenge': _whizChallengeKey,
              'whiz_battle': _whizBattleKey,
              'whiz_puzzle': _whizPuzzleKey,
              'leaderboard': _leaderboardKey,
            },
          ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Image.asset("assets/images-logo/newhomepagelogo.png", width: 150, height: 50, fit: BoxFit.contain),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _buildTopNavButton("Home", Icons.home),
                const SizedBox(width: 40),
                Container(
                  key: _leaderboardKey,  // ← ADD THIS
                  child: _buildTopNavButton("Leaderboard", Icons.leaderboard),
                ),
              ]),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _showSettingsDialog,
              child: Container(
                key: _profileAvatarKey,  // ← ADD THIS LINE
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, border: Border.all(color: const Color(0xFF046EB8), width: 3)),
                child: ClipOval(child: Image.asset(_currentProfile.avatar, fit: BoxFit.cover)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      key: _profileCardKey,
      height: 90,
      width: 850,
      margin: const EdgeInsets.only(top: 60),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF4A90BE),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFFFFD700), width: 3),
            ),
            child: ClipOval(
              child: Image.asset(_currentProfile.avatar, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _currentProfile.username,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () async {
                          try {
                            await _audioService.playClickSound();
                          } catch (e) {
                            debugPrint('Click sound not found: $e');
                          }
                          _editProfile();
                        },
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Color(0xFF046EB8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _currentProfile.category,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  "$cityName, ${_currentProfile.region}",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ✅ HOVER-ACTIVATED STAR WITH TOOLTIP
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _showStarTooltip = true),
            onExit: (_) => setState(() => _showStarTooltip = false),
            child: Stack(
              key: _starCountKey,
              clipBehavior: Clip.none,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: _getStarColor(), size: 24),
                    const SizedBox(width: 6),
                    Text(
                      '${_currentProfile.stars}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                // TOOLTIP
                if (_showStarTooltip)
                  Positioned(
                    left: -20,
                    top: -75,
                    child: Container(
                      width: 290,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(text: 'Your total stars! Earn more by completing '),
                            TextSpan(
                              text: 'Memory Match',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF656BE6),
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Puzzle',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE6833A),
                              ),
                            ),
                            TextSpan(text: ' games quickly.'),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () async {
                try {
                  await _audioService.playClickSound();
                } catch (e) {
                  debugPrint('Click sound not found: $e');
                }
                if (!mounted) return;
                showDialog(
                  context: context,
                  builder: (_) => PlayerBadgesDialog(playerId: _currentProfile.id),
                );
              },
              child: Container(
                key: _badgesButtonKey,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDD000),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDD000), width: 2),
                ),
                child: const Text(
                  'Your Badges',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB8860B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHomeContent() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Align(alignment: Alignment.topCenter, child: _buildProfileCard()),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(top: 180, left: 70, right: 70), // ← CHANGED from 200 to 180
            child: LayoutBuilder(builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 800 ? 2 : 4;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                padding: const EdgeInsets.symmetric(vertical: 20),
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 0.73,
                children: [
                  _GameBox(
                    key: _memoryMatchKey,
                    title: "Whiz Memory Match",
                    imagePath: "assets/images-gamecards/whizmemorymatch.png",
                    backgroundColor: const Color(0xFF656BE6),
                    onTapNavigate: () => _triggerFlashAndNavigate(
                      WhizMemoryMatch(
                        userAvatar: _currentProfile.avatar,
                        playerId: _currentProfile.id,
                        username: _currentProfile.username,
                      ),
                    ),
                  ),
                  _GameBox(
                    key: _whizChallengeKey,
                    title: "Whiz Challenge",
                    imagePath: "assets/images-gamecards/whizchallenge.png",
                    backgroundColor: const Color(0xFFFDD000),
                    onTapNavigate: () => _triggerFlashAndNavigate(
                      WhizChallenge(
                        userAvatar: _currentProfile.avatar,
                        userId: _currentProfile.id,
                        username: _currentProfile.username,
                      ),
                    ),
                  ),
                  _GameBox(
                    key: _whizBattleKey,
                    title: "Whiz Battle",
                    imagePath: "assets/images-gamecards/whizbattle.png",
                    backgroundColor: const Color(0xFFC571E2),
                    onTapNavigate: () => _triggerFlashAndNavigate(
                      WhizBattle(
                        userAvatar: _currentProfile.avatar,
                        userId: _currentProfile.id,
                        username: _currentProfile.username,
                      ),
                    ),
                  ),
                  _GameBox(
                    key: _whizPuzzleKey,
                    title: "Whiz Puzzle",
                    imagePath: "assets/images-gamecards/whizpuzzle.png",
                    backgroundColor: const Color(0xFFE6833A),
                    onTapNavigate: () => _triggerFlashAndNavigate(
                      WhizPuzzle(
                        userAvatar: _currentProfile.avatar,
                        playerId: _currentProfile.id,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ✅ GameBox with upward hover, smooth return, fade, and bounce when hover ends
class _GameBox extends StatefulWidget {
  final String title;
  final String imagePath;
  final Color backgroundColor;
  final VoidCallback onTapNavigate;

  const _GameBox({
    super.key,  // Change to Key? key
    required this.title,
    required this.imagePath,
    required this.backgroundColor,
    required this.onTapNavigate,
  });

  @override
  State<_GameBox> createState() => _GameBoxState();
}

class _GameBoxState extends State<_GameBox> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _floatController;
  late AnimationController _fadeOutController;
  late AnimationController _bounceController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _liftAnimation;
  late Animation<double> _shadowAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;

  bool _hovering = false;
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutBack),
    );

    _liftAnimation = Tween<double>(begin: 0, end: -50).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutBack),
    );

    _shadowAnimation = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeIn),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _floatController.dispose();
    _fadeOutController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _onEnter(PointerEvent details) {
    setState(() => _hovering = true);
    _bounceController.reset();
    _hoverController.forward();
    _floatController.repeat(reverse: true);
  }

  Future<void> _onExit(PointerEvent details) async {
    setState(() => _hovering = false);

    _floatController.stop();
    _floatController.reset();

    await _hoverController.reverse();

    _bounceController.forward();
    await Future.delayed(const Duration(milliseconds: 120));
    _bounceController.reverse();
  }

  Future<void> _onTap() async {
    try {
      await _audioService.playClickSound();
    } catch (e) {
      debugPrint('Click sound not found: $e');
    }

    _floatController.stop();
    setState(() => _hovering = false);

    _hoverController.duration = const Duration(milliseconds: 150);
    await _hoverController.reverse();

    await _fadeOutController.forward();

    widget.onTapNavigate();

    if (mounted) {
      _fadeOutController.reset();
      _hoverController.duration = const Duration(milliseconds: 800);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _hoverController,
            _floatController,
            _fadeOutController,
            _bounceController
          ]),
          builder: (context, child) {
            final floatOffset = _hovering ? sin(_floatController.value * 2 * pi) * 8 : 0;
            final totalOffset = _liftAnimation.value + floatOffset + _bounceAnimation.value;

            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, totalOffset),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (_hovering)
                      Container(
                        width: 320,
                        height: 400,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.yellow.withValues(alpha: 0.4 * _glowAnimation.value),
                              blurRadius: 50,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      bottom: -30,
                      child: Container(
                        width: 180 * _shadowAnimation.value,
                        height: 35,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(_hovering ? _rotationAnimation.value : 0),
                      child: Container(
                        width: 280,
                        height: 360,
                        decoration: BoxDecoration(
                          color: widget.backgroundColor,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white, width: 5),
                          boxShadow: [
                            BoxShadow(
                              color: widget.backgroundColor.withValues(alpha: 0.7),
                              blurRadius: 30,
                              spreadRadius: 5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                child: Image.asset(
                                  widget.imagePath,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 22),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              child: Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  color: widget.backgroundColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ✅ Settings Dialog Widget - UPDATED WITH AUDIO SERVICE INTEGRATION
class _SettingsDialog extends StatefulWidget {
  final String userId;
  final String baseUrl;
  final VoidCallback onLogout;
  final VoidCallback onEditProfile; // ✅ NEW

  const _SettingsDialog({
    required this.userId,
    required this.baseUrl,
    required this.onLogout,
    required this.onEditProfile, // ✅ NEW
  });

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  double _volumeLevel = 50;  // Music volume
  double _sfxLevel = 50;     // SFX volume
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load from SharedPreferences
      _volumeLevel = prefs.getDouble('music_volume_${widget.userId}') ?? 50.0;
      _sfxLevel = prefs.getDouble('sfx_volume_${widget.userId}') ?? 50.0;
    });

    // Apply to AudioService
    await _audioService.setMusicVolume(_volumeLevel / 100.0);
    // Note: We'll need to add setSfxVolume to AudioService if it doesn't exist
    // For now, if volume is 0, disable; otherwise enable
    bool shouldEnableMusic = _volumeLevel > 0;
    bool shouldEnableSfx = _sfxLevel > 0;

    if (!shouldEnableMusic && _audioService.isMusicEnabled) {
      _audioService.toggleMusic();
    } else if (shouldEnableMusic && !_audioService.isMusicEnabled) {
      _audioService.toggleMusic();
    }

    if (!shouldEnableSfx && _audioService.isSfxEnabled) {
      _audioService.toggleSfx();
    } else if (shouldEnableSfx && !_audioService.isSfxEnabled) {
      _audioService.toggleSfx();
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('music_volume_${widget.userId}', _volumeLevel);
    await prefs.setDouble('sfx_volume_${widget.userId}', _sfxLevel);
  }

  void _onVolumeChanged(double value) {
    setState(() => _volumeLevel = value);
    _audioService.setMusicVolume(value / 100.0);

    // If volume is 0, disable music; otherwise enable it
    bool shouldEnableMusic = value > 0;
    if (!shouldEnableMusic && _audioService.isMusicEnabled) {
      _audioService.toggleMusic();
    } else if (shouldEnableMusic && !_audioService.isMusicEnabled) {
      _audioService.toggleMusic();
    }

    _saveSettings();
  }

  void _onSfxVolumeChanged(double value) {
    setState(() => _sfxLevel = value);

    // If volume is 0, disable SFX; otherwise enable it
    bool shouldEnableSfx = value > 0;
    if (!shouldEnableSfx && _audioService.isSfxEnabled) {
      _audioService.toggleSfx();
    } else if (shouldEnableSfx && !_audioService.isSfxEnabled) {
      _audioService.toggleSfx();
    }

    _saveSettings();
  }

  Future<void> _handleRateGame() async {
    // Check rating status first
    final prefs = await SharedPreferences.getInstance();
    final hasRated = prefs.getBool('hasRated_${widget.userId}') ?? false;

    if (!hasRated && mounted) {
      // ✅ Close settings dialog first
      if (!mounted) return;
      Navigator.of(context).pop();

      // Small delay for smooth transition
      await Future.delayed(const Duration(milliseconds: 150));

      // ✅ Show the proper rating dialog (standalone popup)
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => _RatingDialog(
          userId: widget.userId,
          baseUrl: widget.baseUrl,
          onRatingSubmitted: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('hasRated_${widget.userId}', true);
          },
        ),
      );
    } else {
      // User already rated - close settings and show snackbar
      if (!mounted) return;
      Navigator.of(context).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already rated this game. Thank you!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _handleLogout() async {
    // Show initial confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
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
                      onPressed: () => Navigator.of(dialogContext).pop(false),
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
                        "No",
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
                      onPressed: () => Navigator.of(dialogContext).pop(true),
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
      ),
    );

    if (confirmed != true) {
      // User clicked "No" - close settings dialog and stay logged in
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    // User clicked "Yes" - close settings dialog and logout immediately
    if (!mounted) return;
    Navigator.of(context).pop();

    // Proceed with logout directly without rating prompts
    if (!mounted) return;
    debugPrint('✅ Logging out');
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: _buildSettingsContent(),
    );
  }

  Widget _buildSettingsContent() {
    return Container(
      key: const ValueKey('settings'),
      width: 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.settings, color: Color(0xFF046EB8), size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF046EB8),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF046EB8)),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Volume Control
          const Row(
            children: [
              Icon(Icons.music_note, color: Color(0xFF046EB8), size: 20),
              SizedBox(width: 8),
              Text(
                'Music Volume',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _volumeLevel,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  activeColor: const Color(0xFF046EB8),
                  inactiveColor: Colors.grey[300],
                  onChanged: _onVolumeChanged,
                ),
              ),
              SizedBox(
                width: 35,
                child: Text(
                  '${_volumeLevel.round()}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // SFX Volume Control
          const Row(
            children: [
              Icon(Icons.graphic_eq, color: Color(0xFF046EB8), size: 20),
              SizedBox(width: 8),
              Text(
                'Sound Effects Volume',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _sfxLevel,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  activeColor: const Color(0xFF046EB8),
                  inactiveColor: Colors.grey[300],
                  onChanged: _onSfxVolumeChanged,
                ),
              ),
              SizedBox(
                width: 35,
                child: Text(
                  '${_sfxLevel.round()}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Divider
          const Divider(),
          const SizedBox(height: 16),

          // Rate Game Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleRateGame,
              icon: const Icon(Icons.star_rounded, size: 20),
              label: const Text(
                'Rate Game',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDD000),
                foregroundColor: const Color(0xFF816A03),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ✅ Edit Profile Button (between Rate Game and Logout)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // close settings dialog
                widget.onEditProfile();      // open edit profile dialog
              },
              icon: const Icon(Icons.edit, size: 20),
              label: const Text(
                'Edit Profile',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF046EB8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, size: 20),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF046EB8),
                side: const BorderSide(color: Color(0xFF046EB8), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ✅ Rating Dialog Widget
class _RatingDialog extends StatefulWidget {
  final String userId;
  final String baseUrl;
  final VoidCallback? onRatingSubmitted;

  const _RatingDialog({
    required this.userId,
    required this.baseUrl,
    this.onRatingSubmitted,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _rating = 0;
  String _feedback = '';
  bool _isSubmitting = false;

  Future<void> _submitRating() async {
    debugPrint('🔍 Submit button clicked in rating dialog');

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // ✅ FRONTEND-ONLY: Store rating locally using SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // Save rating data
      await prefs.setInt('rating_${widget.userId}', _rating);
      await prefs.setString('feedback_${widget.userId}', _feedback);
      await prefs.setString('rating_timestamp_${widget.userId}', DateTime.now().toIso8601String());

      // Optional: Print to console for debugging (you can see the ratings)
      debugPrint('⭐ Rating saved locally:');
      debugPrint('User ID: ${widget.userId}');
      debugPrint('Rating: $_rating stars');
      debugPrint('Feedback: $_feedback');
      debugPrint('Timestamp: ${DateTime.now()}');

      if (mounted) {
        // Call the callback to mark user as rated
        widget.onRatingSubmitted?.call();

        // ✅ Pop dialog first to return the result
        Navigator.pop(context, true); // Return true when rating is submitted

        // Small delay to ensure context is valid
        await Future.delayed(const Duration(milliseconds: 100));

        // Then show snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for your rating!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving rating: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              color: Color(0xFFFDD000),
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'Rate Our Game!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF046EB8),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your feedback helps us improve',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFDD000),
                      size: 40,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Feedback TextField
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                maxLines: 3,
                style: const TextStyle(fontFamily: 'Poppins'),
                decoration: const InputDecoration(
                  hintText: 'Share your thoughts (optional)',
                  hintStyle: TextStyle(fontFamily: 'Poppins'),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                onChanged: (value) => _feedback = value,
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSubmitting ? null : () {
                      debugPrint('🔍 Later button clicked in rating dialog');
                      Navigator.pop(context, false);
                    },
                    child: const Text(
                      'Later',
                      style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD000),
                      foregroundColor: const Color(0xFF816A03),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF816A03)),
                      ),
                    )
                        : const Text(
                      'Submit',
                      style: TextStyle(
                        fontFamily: 'Poppins',
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
    );
  }
}