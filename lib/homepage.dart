import 'package:flutter/material.dart';
import 'edit_profile.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF046EB8), // ✅ background
      body: Column(
        children: [
          // ===== TOP BAR =====
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                // Logo with image (bigger PNG, bar stays slim)
                Image.asset(
                  "assets/images-logo/mainlogo.png",
                  width: 150,
                  height: 50,
                  fit: BoxFit.contain,
                ),

                // Centered Menu
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            "Home",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 20),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            "Stats",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Avatar placeholder
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
              ],
            ),
          ),

          // ===== MAIN CONTENT WITH STACK =====
          Expanded(
            child: Stack(
              children: [
                // ==== GAME BUTTON GRID ====
                Padding(
                  padding: const EdgeInsets.only(top: 200, left: 70, right: 70),
                  child: GridView.count(
                    crossAxisCount: 4,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.80, // taller than wide
                    children: const [
                      _GameBox(
                        title: "Whiz Memory Match",
                        imagePath: "assets/images-icons/placeholder.png",
                      ),
                      _GameBox(
                        title: "Whiz Challenge",
                        imagePath: "assets/images-icons/placeholder.png",
                      ),
                      _GameBox(
                        title: "Whiz Battle",
                        imagePath: "assets/images-icons/placeholder.png",
                      ),
                      _GameBox(
                        title: "Whiz Puzzle",
                        imagePath: "assets/images-icons/placeholder.png",
                      ),
                    ],
                  ),
                ),

                // ==== PROFILE CARD ====
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 780,
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
                        const CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.yellow,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.brown,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Profile details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                "juandelacruz",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Student",
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                "Makati City, Metro Manila, NCR",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Buttons Row
                        Row(
                          children: [
                            // Edit Profile button
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const EditProfileDialog(),
                                );
                              },
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

                            // Your Badges button
                            ElevatedButton.icon(
                              onPressed: () {
                                print("Your Badges clicked");
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFDD000),
                                foregroundColor: const Color(0xFF816A03),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.emoji_events),
                              label: const Text(
                                "Your Badges",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
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

// ===== GAME BOX WIDGET =====
class _GameBox extends StatefulWidget {
  final String title;
  final String imagePath;
  const _GameBox({required this.title, required this.imagePath});

  @override
  State<_GameBox> createState() => _GameBoxState();
}

class _GameBoxState extends State<_GameBox> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () {
          print("${widget.title} clicked"); // clickable but placeholder
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hovering ? Colors.yellow.shade300 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _hovering
                ? [const BoxShadow(color: Colors.black26, blurRadius: 8)]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Game icon (fills available vertical space)
              Expanded(
                child: Center(
                  child: Image.asset(
                    widget.imagePath,
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Title closer to bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
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
