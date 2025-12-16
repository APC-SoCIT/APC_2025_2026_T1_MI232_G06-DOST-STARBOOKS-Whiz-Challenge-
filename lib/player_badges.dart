import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:confetti/confetti.dart';

class PlayerBadgesDialog extends StatefulWidget {
  final String playerId;

  const PlayerBadgesDialog({
    super.key,
    required this.playerId,
  });

  @override
  State<PlayerBadgesDialog> createState() => _PlayerBadgesDialogState();
}

class _PlayerBadgesDialogState extends State<PlayerBadgesDialog> {
  bool isLoading = true;
  Map<String, dynamic>? badgeData;
  List<dynamic> unclaimedBadges = [];
  String? errorMessage;
  final String baseUrl = "http://127.0.0.1:8000";

  final Map<String, String> badgeImages = {
    "easy": "assets/images-badges/whiz-ready.png",
    "average": "assets/images-badges/whiz-happy.png",
    "difficult": "assets/images-badges/whiz-achiever.png",
  };

  final Map<String, Color> badgeColors = {
    "easy": const Color(0xFF1D9358),
    "average": const Color(0xFF046EB8),
    "difficult": const Color(0xFFBD442E),
  };

  @override
  void initState() {
    super.initState();
    _fetchPlayerBadges();
  }

  Future<void> _fetchPlayerBadges() async {
    try {
      final summaryResponse = await http.get(
        Uri.parse('$baseUrl/api/badges/player/${widget.playerId}/summary'),
      );

      final unclaimedResponse = await http.get(
        Uri.parse('$baseUrl/api/badges/official/player/${widget.playerId}/unclaimed'),
      );

      if (summaryResponse.statusCode == 200 && unclaimedResponse.statusCode == 200) {
        final summaryData = json.decode(summaryResponse.body);
        final unclaimedData = json.decode(unclaimedResponse.body);

        if (summaryData['success'] && unclaimedData['success']) {
          setState(() {
            badgeData = summaryData['data'];
            unclaimedBadges = unclaimedData['data']['badges'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Failed to load badges: ${summaryData['message'] ?? unclaimedData['message']}';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${summaryResponse.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading badges: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _claimBadge(String difficulty) async {
    try {
      final badgeToClaim = unclaimedBadges.firstWhere(
            (badge) => badge['difficulty'] == difficulty && badge['claimed'] == false,
        orElse: () => null,
      );

      if (badgeToClaim == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No badge available to claim'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Extract the badge ID properly from MongoDB structure
      String? badgeId;

      if (badgeToClaim['_id'] is Map) {
        badgeId = badgeToClaim['_id']['\$oid'];
      } else if (badgeToClaim['_id'] is String) {
        badgeId = badgeToClaim['_id'];
      } else {
        badgeId = badgeToClaim['_id']?.toString();
      }

      if (badgeId == null || badgeId.isEmpty || badgeId == 'null') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid badge ID'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/badges/official/$badgeId/claim'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          await _fetchPlayerBadges();

          if (mounted) {
            // Show beautiful success dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => _ClaimSuccessDialog(
                difficulty: difficulty,
                borderColor: badgeColors[difficulty] ?? Colors.grey,
                badgeImage: badgeImages[difficulty] ?? "",
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed: ${data['message'] ?? 'Unknown error'}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server error: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error claiming badge: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _hasUnclaimedBadge(String difficulty) {
    return unclaimedBadges.any((badge) =>
    badge['difficulty'] == difficulty && badge['claimed'] == false);
  }

  bool _hasClaimedBadge(String difficulty) {
    if (badgeData == null) return false;
    final officialBadges = badgeData!['official_badges'];
    return (officialBadges[difficulty] ?? 0) > 0;
  }

  Map<String, int> _getProgress(String difficulty) {
    if (badgeData == null) {
      return {'current': 0, 'needed': 3, 'remaining': 3};
    }

    final progress = badgeData!['progress'][difficulty];
    return {
      'current': progress['current_count'] ?? 0,
      'needed': 3,
      'remaining': progress['badges_remaining'] ?? 3,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 410, maxHeight: 750),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                          errorMessage = null;
                        });
                        _fetchPlayerBadges();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
                : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBadgeCategory("Easy", "easy"),
                  const SizedBox(height: 20),
                  _buildBadgeCategory("Average", "average"),
                  const SizedBox(height: 20),
                  _buildBadgeCategory("Difficult", "difficult"),
                ],
              ),
            ),
          ),
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

  Widget _buildBadgeCategory(String title, String difficulty) {
    if (badgeData == null) return const SizedBox.shrink();

    final progress = _getProgress(difficulty);
    final hasUnclaimed = _hasUnclaimedBadge(difficulty);
    final hasClaimed = _hasClaimedBadge(difficulty);

    final borderColor = badgeColors[difficulty] ?? Colors.grey;
    final badgeImage = badgeImages[difficulty] ?? "";

    final currentInSet = progress['current']!;

    // Generate badge display based on state
    List<String?> badgePaths;

    if (hasClaimed) {
      // After claiming: Show ALL 3 filled badges
      badgePaths = [badgeImage, badgeImage, badgeImage];
    } else if (hasUnclaimed) {
      // Ready to claim: Show all 3 filled badges
      badgePaths = [badgeImage, badgeImage, badgeImage];
    } else {
      // In progress: Show current progress (0, 1, or 2 badges)
      badgePaths = List.generate(3, (i) => i < currentInSet ? badgeImage : null);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: borderColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                hasClaimed
                    ? 'Complete'
                    : (hasUnclaimed ? '3/3' : '$currentInSet/3'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: borderColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ...List.generate(3, (i) {
              final path = badgePaths[i];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: path != null ? borderColor : Colors.grey.shade300,
                      width: 3,
                    ),
                    color: path == null ? Colors.grey.shade100 : null,
                  ),
                  child: path != null
                      ? ClipOval(
                      child: Image.asset(path, fit: BoxFit.contain))
                      : Center(
                    child: Icon(
                      Icons.lock_outline,
                      color: Colors.grey.shade400,
                      size: 30,
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            ElevatedButton(
              onPressed: hasUnclaimed ? () => _claimBadge(difficulty) : () {},  // Always enabled, but does nothing when claimed
              style: ElevatedButton.styleFrom(
                backgroundColor: hasUnclaimed
                    ? borderColor
                    : (hasClaimed ? Colors.white : Colors.grey.shade300),
                foregroundColor: hasUnclaimed
                    ? Colors.white
                    : (hasClaimed ? borderColor : Colors.grey.shade600),  // CLAIMED text = borderColor (green/blue/red)
                side: hasClaimed
                    ? BorderSide(color: borderColor, width: 2)
                    : null,
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
              child: Text(hasUnclaimed
                  ? "CLAIM!"
                  : (hasClaimed ? "CLAIMED" : "LOCKED")),
            ),
          ],
        ),
      ],
    );
  }
}

// Animated Claim Success Dialog
class _ClaimSuccessDialog extends StatefulWidget {
  final String difficulty;
  final Color borderColor;
  final String badgeImage;

  const _ClaimSuccessDialog({
    required this.difficulty,
    required this.borderColor,
    required this.badgeImage,
  });

  @override
  State<_ClaimSuccessDialog> createState() => _ClaimSuccessDialogState();
}

class _ClaimSuccessDialogState extends State<_ClaimSuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _textController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _textAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );

    // Start animations
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _textController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti animation at the very top of screen
        Positioned(
          top: -150,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: true,
            child: SizedBox(
              height: 300,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(10, (index) {
                  return ConfettiWidget(
                    confettiController: ConfettiController(duration: const Duration(seconds: 3))..play(),
                    blastDirection: 3.14159 / 2, // pi/2
                    emissionFrequency: 0.05,
                    numberOfParticles: 10,
                    maxBlastForce: 15,
                    minBlastForce: 8,
                    gravity: 0.3,
                    colors: const [
                      Color(0xFFFDD000),
                      Color(0xFF5F6FDB),
                      Color(0xFF046EB8),
                      Colors.red,
                      Colors.green,
                      Colors.orange,
                      Colors.pink,
                      Colors.purple,
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
        // Main dialog
        Center(
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.borderColor, width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Large badge image with glow and scale animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: widget.borderColor, width: 5),
                        boxShadow: [
                          BoxShadow(
                            color: widget.borderColor.withValues(alpha: 0.25),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(widget.badgeImage, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Congratulations text with fade-in
                  FadeTransition(
                    opacity: _textAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_textAnimation),
                      child: Text(
                        'FANTASTIC!',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: widget.borderColor,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Success message with icon
                  FadeTransition(
                    opacity: _textAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.borderColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: widget.borderColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                                children: [
                                  const TextSpan(text: 'You finished the '),
                                  TextSpan(
                                    text: '${widget.difficulty.toUpperCase()} BADGE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: widget.borderColor,
                                    ),
                                  ),
                                  const TextSpan(text: '!\nNow claim your prize!'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Continue Playing button
                  FadeTransition(
                    opacity: _textAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      child:                       ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);  // Just close the success dialog, stay on badges dialog
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text(
                          'Continue Playing',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.borderColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}