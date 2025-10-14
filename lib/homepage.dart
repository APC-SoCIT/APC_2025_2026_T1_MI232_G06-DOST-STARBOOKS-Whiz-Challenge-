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

// ✅ USER PROFILE MODEL
class UserProfile {
  String id;
  String username;
  String school;
  String age;
  String category;
  String sex;
  String region;
  String province;
  String city;
  String avatar;

  UserProfile({
    required this.id,
    required this.username,
    required this.school,
    required this.age,
    required this.category,
    required this.sex,
    required this.region,
    required this.province,
    required this.city,
    required this.avatar,
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
      sex: json['sex'] ?? '',
      region: json['region']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      avatar: json['avatar'] ?? "assets/images-avatars/Adventurer.png",
    );
  }

  UserProfile copyWith({
    String? username,
    String? school,
    String? age,
    String? category,
    String? sex,
    String? region,
    String? province,
    String? city,
    String? avatar,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      school: school ?? this.school,
      age: age ?? this.age,
      category: category ?? this.category,
      sex: sex ?? this.sex,
      region: region ?? this.region,
      province: province ?? this.province,
      city: city ?? this.city,
      avatar: avatar ?? this.avatar,
    );
  }
}

// ✅ HOME PAGE
class HomePage extends StatefulWidget {
  final UserProfile profile;
  final String initialTab;

  const HomePage({super.key, required this.profile, this.initialTab = "Home"});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late UserProfile _currentProfile;
  late String _selectedTab;

  bool _loadingProfile = true;
  final String baseUrl = "http://127.0.0.1:8000";

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
    _selectedTab = widget.initialTab;
    _loadUserWithLocationNames();
  }

  Future<void> _loadUserWithLocationNames() async {
    setState(() => _loadingProfile = true);
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/homepage/${_currentProfile.id}"));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final user = data['user'];
          setState(() {
            _currentProfile = _currentProfile.copyWith(
              region: user['region'] ?? '',
              province: user['province'] ?? '',
              city: user['city'] ?? '',
            );
            _loadingProfile = false;
          });
        }
      } else {
        debugPrint("❌ Failed to load user with location names: ${res.body}");
        setState(() => _loadingProfile = false);
      }
    } catch (e) {
      debugPrint("❌ Error loading user with location names: $e");
      setState(() => _loadingProfile = false);
    }
  }

  String get regionName => _currentProfile.region.isNotEmpty ? _currentProfile.region : "Unknown Region";
  String get provinceName => _currentProfile.province.isNotEmpty ? _currentProfile.province : "Unknown Province";
  String get cityName => _currentProfile.city.isNotEmpty ? _currentProfile.city : "Unknown City";

  Future<void> _editProfile() async {
    final updatedProfile = await showDialog<UserProfile>(
      context: context,
      builder: (_) => EditProfileDialog(profile: _currentProfile),
    );
    if (updatedProfile != null && mounted) {
      setState(() {
        _currentProfile = updatedProfile;
      });
    }
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
              Image.asset("assets/images-icons/sadlogout.png", width: 80, height: 80),
              const SizedBox(height: 15),
              const Text("Logout Confirmation",
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              const Text("Are you sure you want to log out?",
                  textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF046EB8), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Cancel",
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Color(0xFF046EB8))),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Logout",
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LogInPage()));
    }
  }

  Widget _buildTopNavButton(String label, IconData icon) {
    final isActive = _selectedTab == label;
    return InkWell(
      onTap: () => setState(() => _selectedTab = label),
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

  @override
  Widget build(BuildContext context) {
    final mainContent = _selectedTab == "Leaderboard" ? const Leaderboard() : _buildHomeContent();

    return Scaffold(
      backgroundColor: const Color(0xFF046EB8),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(children: [
        _buildTopBar(),
        Expanded(child: mainContent),
      ]),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Image.asset("assets/images-logo/mainlogo.png", width: 150, height: 50, fit: BoxFit.contain),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _buildTopNavButton("Home", Icons.home),
                const SizedBox(width: 40),
                _buildTopNavButton("Leaderboard", Icons.leaderboard),
              ]),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _logoutDialog,
              child: Container(
                width: 44,
                height: 44,
                decoration:
                BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF046EB8), width: 3)),
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
      height: 110,
      width: 800,
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF4A90BE),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD13B), width: 5),
              color: Colors.white,
            ),
            child: ClipOval(child: Image.asset(_currentProfile.avatar, fit: BoxFit.cover)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_currentProfile.username,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.person, color: Colors.white, size: 16),
                  const SizedBox(width: 5),
                  Text(_currentProfile.category,
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 16),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text("$cityName, $provinceName, $regionName",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ],
            ),
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _editProfile,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text("Edit Profile", style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF046EB8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(context: context, builder: (_) => const PlayerBadgesDialog());
                },
                icon: const Icon(Icons.emoji_events, size: 16),
                label: const Text("Your Badges",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDD000),
                    foregroundColor: const Color(0xFF915701),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 160, left: 70, right: 70),
          child: LayoutBuilder(builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 800 ? 2 : 4;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              padding: const EdgeInsets.symmetric(vertical: 20),
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 0.73,
              children: const [
                _GameBox(
                    title: "Whiz Memory Match",
                    imagePath: "assets/images-icons/memorymatch.png",
                    backgroundColor: Color(0xFF656BE6)),
                _GameBox(
                    title: "Whiz Challenge",
                    imagePath: "assets/images-icons/whizchallenge.png",
                    backgroundColor: Color(0xFFFDD000)),
                _GameBox(
                    title: "Whiz Battle",
                    imagePath: "assets/images-icons/whizbattle.png",
                    backgroundColor: Color(0xFFC571E2)),
                _GameBox(
                    title: "Whiz Puzzle",
                    imagePath: "assets/images-icons/whizpuzzle.png",
                    backgroundColor: Color(0xFFE6833A)),
              ],
            );
          }),
        ),
        Align(alignment: Alignment.topCenter, child: _buildProfileCard()),
      ],
    );
  }
}

// ✅ GameBox with LIFT + TWIRL animation
class _GameBox extends StatefulWidget {
  final String title;
  final String imagePath;
  final Color backgroundColor;

  const _GameBox({
    required this.title,
    required this.imagePath,
    required this.backgroundColor,
  });

  @override
  State<_GameBox> createState() => _GameBoxState();
}

class _GameBoxState extends State<_GameBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _liftAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _rotationAnimation = Tween<double>(begin: 0, end: pi).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));
    _liftAnimation = Tween<double>(begin: 0, end: -10)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToGame(BuildContext context) {
    Widget page;
    switch (widget.title) {
      case "Whiz Memory Match":
        page = const WhizMemoryMatch();
        break;
      case "Whiz Challenge":
        page = const WhizChallenge();
        break;
      case "Whiz Battle":
        page = const WhizBattle();
        break;
      case "Whiz Puzzle":
        page = const WhizPuzzle();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(from: 0),
      onExit: (_) => _controller.reverse(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _navigateToGame(context),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final isBack = _rotationAnimation.value > pi / 2;
            return Transform(
              transform: Matrix4.identity()
                ..translate(0.0, _liftAnimation.value)
                ..rotateY(_rotationAnimation.value),
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white, width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD13B)
                          .withValues(alpha: isBack ? 0.4 : 0.8),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: isBack
                    ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: _buildBackSide(),
                )
                    : _buildFrontSide(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFrontSide() {
    return Column(children: [
      Expanded(child: Center(child: Image.asset(widget.imagePath, fit: BoxFit.contain))),
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
    ]);
  }

  Widget _buildBackSide() {
    return Column(children: [
      Expanded(child: Center(child: Image.asset(widget.imagePath, fit: BoxFit.contain))),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: Colors.white, width: 5),
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
    ]);
  }
}
