import 'package:flutter/material.dart';

class PlayerBadgesDialog extends StatefulWidget {
  const PlayerBadgesDialog({super.key});

  @override
  State<PlayerBadgesDialog> createState() => _PlayerBadgesDialogState();
}

class _PlayerBadgesDialogState extends State<PlayerBadgesDialog> {
  // Track claim states
  final Map<String, bool> claimed = {
    "Easy": false,
    "Average": false,
    "Difficult": false,
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ==== Main White Box ====
          Container(
            constraints: const BoxConstraints(maxWidth: 410, maxHeight: 750),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBadgeCategory(
                    "Easy",
                    const Color(0xFF1D9358),
                    [
                      "assets/images-badges/whiz-ready.png",
                      "assets/images-badges/whiz-ready.png",
                      "assets/images-badges/whiz-ready.png",
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildBadgeCategory(
                    "Average",
                    const Color(0xFF046EB8),
                    [
                      "assets/images-badges/whiz-happy.png",
                      "assets/images-badges/whiz-happy.png",
                      null, // missing one
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildBadgeCategory(
                    "Difficult",
                    const Color(0xFFBD442E),
                    [
                      "assets/images-badges/whiz-achiever.png",
                      null,
                      null,
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ==== Top-Center Image (overlapping) ====
          Positioned(
            top: -74,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                "assets/images-badges/whiz-achiever.png",
                width: 220,
                height: 145,
              ),
            ),
          ),

          // ==== Close Button ====
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  // ==== Badge Row Builder ====
  Widget _buildBadgeCategory(
      String title, Color borderColor, List<String?> badgePaths) {
    bool unlocked = badgePaths.every((p) => p != null);
    bool isClaimed = claimed[title] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: borderColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Always show 3 badge slots
            ...List.generate(3, (i) {
              final path = i < badgePaths.length ? badgePaths[i] : null;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: path != null ? borderColor : Colors.grey,
                        width: 3),
                  ),
                  child: path != null
                      ? ClipOval(
                          child: Image.asset(path, fit: BoxFit.contain),
                        )
                      : null,
                ),
              );
            }),
            const Spacer(),
            ElevatedButton(
              onPressed: unlocked && !isClaimed
                  ? () {
                      setState(() {
                        claimed[title] = true;
                      });
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isClaimed
                    ? Colors.grey
                    : (unlocked ? borderColor : Colors.grey),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 17),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text(
                isClaimed
                    ? "CLAIMED"
                    : (unlocked ? "CLAIM!" : "LOCKED"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
