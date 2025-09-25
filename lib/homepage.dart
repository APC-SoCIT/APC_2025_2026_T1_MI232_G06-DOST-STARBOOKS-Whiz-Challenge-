import 'package:flutter/material.dart';
import 'edit_profile.dart';
import 'player_badges.dart';
import 'whiz_battle.dart';
import 'whiz_challenge.dart';
import 'whiz_puzzle.dart';
import 'whiz_memory_match.dart';

class UserProfile {
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
    this.username = "editmyusername",
    this.school = "Type your School",
    this.age = "18-22",
    this.category = "Student",
    this.sex = "Prefer not to say",
    this.region = "NCR",
    this.province = "Metro Manila",
    this.city = "Makati City",
    this.avatar = "Astronaut",
  });
}

class HomePage extends StatefulWidget {
  final UserProfile profile;
  const HomePage({super.key, required this.profile});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _editProfile() async {
    final updatedProfile = await showDialog<UserProfile>(
      context: context,
      builder: (_) => EditProfileDialog(profile: widget.profile),
    );

    if (updatedProfile != null) {
      setState(() {
        widget.profile.username = updatedProfile.username;
        widget.profile.school = updatedProfile.school;
        widget.profile.age = updatedProfile.age;
        widget.profile.category = updatedProfile.category;
        widget.profile.sex = updatedProfile.sex;
        widget.profile.region = updatedProfile.region;
        widget.profile.province = updatedProfile.province;
        widget.profile.city = updatedProfile.city;
        widget.profile.avatar = updatedProfile.avatar;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF046EB8), // background
      body: Column(
        children: [
          // ===== TOP BAR =====
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
                        TextButton(
                          onPressed: () {},
                          child: const Text("Home",
                              style: TextStyle(color: Colors.black)),
                        ),
                        const SizedBox(width: 20),
                        TextButton(
                          onPressed: () {},
                          child: const Text("Stats",
                              style: TextStyle(color: Colors.black)),
                        ),
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
                      color: const Color(0xFFFFD13B),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      "assets/images-avatars/${widget.profile.avatar}.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ===== MAIN CONTENT =====
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 190, left: 70, right: 70),
                  child: GridView.count(
                    crossAxisCount: 4,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.78,
                    children: const [
                      _GameBox(
                        title: "Whiz Memory Match",
                        imagePath: "assets/images-icons/memorymatch.png",
                        backgroundColor: Color(0xFF656BE6),
                      ),
                      _GameBox(
                        title: "Whiz Challenge",
                        imagePath: "assets/images-icons/whizchallenge.png",
                        backgroundColor: Color(0xFFFDD000),
                      ),
                      _GameBox(
                        title: "Whiz Battle",
                        imagePath: "assets/images-icons/whizbattle.png",
                        backgroundColor: Color(0xFFC571E2),
                      ),
                      _GameBox(
                        title: "Whiz Puzzle",
                        imagePath: "assets/images-icons/whizpuzzle.png",
                        backgroundColor: Color(0xFFE6833A),
                      ),
                    ],
                  ),
                ),

                // ==== PROFILE CARD ====
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 130,
                    width: 800,
                    margin: const EdgeInsets.only(top: 30),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90BE),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFFD13B),
                              width: 6,
                            ),
                            color: Colors.white,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              "assets/images-avatars/${widget.profile.avatar}.png",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Profile details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.profile.username,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(widget.profile.category,
                                  style:
                                      const TextStyle(color: Colors.white70)),
                              Text(
                                "${widget.profile.city}, ${widget.profile.province}, ${widget.profile.region}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _editProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF046EB8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.edit),
                              label: const Text("Edit Profile"),
                            ),
                            const SizedBox(width: 14),
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const PlayerBadgesDialog(),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFDD000),
                                foregroundColor: Color(0xFF915701),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.emoji_events),
                              label: const Text("Your Badges",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===== GAME BOX =====
class _GameBox extends StatefulWidget {
  final String title;
  final String imagePath;
  final Color backgroundColor;

  const _GameBox({
    required this.title,
    required this.imagePath,
    this.backgroundColor = Colors.white,
  });

  @override
  State<_GameBox> createState() => _GameBoxState();
}

class _GameBoxState extends State<_GameBox> {
  bool _hovering = false;

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
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () => _navigateToGame(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color:
                          const Color.fromARGB(255, 255, 209, 59).withOpacity(0.8),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SizedBox(
                    height: 710,
                    width: 400,
                    child: Image.asset(widget.imagePath, fit: BoxFit.contain),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
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
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
