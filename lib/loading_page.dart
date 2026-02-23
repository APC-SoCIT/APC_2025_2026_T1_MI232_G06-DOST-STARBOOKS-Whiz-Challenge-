import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Full-page loading screen with three birds bouncing trail animation
/// and geometric pattern with spinning pinwheels in the background
class LoadingPage extends StatefulWidget {
  final String? message;

  const LoadingPage({
    super.key,
    this.message,
  });

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late List<AnimationController> _pinwheelControllers;

  // Pinwheel positions (12 pinwheels in symmetrical grid around center)
  final List<Map<String, dynamic>> _pinwheelPositions = [
    // Top row - 3 flowers (KEEP at 0.08 from top)
    {'top': 0.08, 'left': 0.05, 'speed': 15.0, 'reverse': false},
    {'top': 0.08, 'left': 0.5, 'speed': 20.0, 'reverse': true, 'centered': true},
    {'top': 0.08, 'right': 0.05, 'speed': 15.0, 'reverse': false},

    // Row 2 - MOVED UP MORE to 0.22
    {'top': 0.22, 'left': 0.20, 'speed': 18.0, 'reverse': true},
    {'top': 0.22, 'right': 0.20, 'speed': 17.0, 'reverse': false},

    // Row 3 - middle (KEEP at 0.5 - center)
    {'top': 0.5, 'left': 0.05, 'speed': 20.0, 'reverse': false, 'centerY': true},
    {'top': 0.5, 'right': 0.05, 'speed': 19.0, 'reverse': true, 'centerY': true},

    // Row 4 - MOVED UP MORE to 0.64
    {'top': 0.64, 'left': 0.20, 'speed': 16.0, 'reverse': false},
    {'top': 0.64, 'right': 0.20, 'speed': 18.0, 'reverse': true},

    // Bottom row - 3 flowers (KEEP at 0.92 from top, or 0.08 from bottom)
    {'bottom': 0.08, 'left': 0.05, 'speed': 17.0, 'reverse': true},
    {'bottom': 0.08, 'left': 0.5, 'speed': 15.0, 'reverse': false, 'centered': true},
    {'bottom': 0.08, 'right': 0.05, 'speed': 20.0, 'reverse': true},
  ];

  @override
  void initState() {
    super.initState();

    // Bouncing animation for the birds
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Create animation controllers for each pinwheel
    _pinwheelControllers = _pinwheelPositions.map((pos) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(seconds: pos['speed'].toInt()),
      )..repeat(reverse: pos['reverse']);
      return controller;
    }).toList();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    for (var controller in _pinwheelControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB), // Sky blue background
      body: Stack(
        children: [
          // Geometric pattern background
          Positioned.fill(
            child: CustomPaint(
              painter: GeometricPatternPainter(),
            ),
          ),

          // Pinwheels scattered around
          ..._buildPinwheels(size),

          // Main content WITHOUT backdrop
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Three birds bouncing trail animation
                SizedBox(
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Bird 1 (left)
                      AnimatedBuilder(
                        animation: _bounceController,
                        builder: (context, child) {
                          final progress = _bounceController.value;
                          final bounceValue = _calculateBounce(progress, 0.0);
                          return Transform.translate(
                            offset: Offset(-120, bounceValue),
                            child: _buildBird(progress, 0.0),
                          );
                        },
                      ),
                      // Bird 2 (middle)
                      AnimatedBuilder(
                        animation: _bounceController,
                        builder: (context, child) {
                          final progress = _bounceController.value;
                          final bounceValue = _calculateBounce(progress, 0.15);
                          return Transform.translate(
                            offset: Offset(0, bounceValue),
                            child: _buildBird(progress, 0.15),
                          );
                        },
                      ),
                      // Bird 3 (right)
                      AnimatedBuilder(
                        animation: _bounceController,
                        builder: (context, child) {
                          final progress = _bounceController.value;
                          final bounceValue = _calculateBounce(progress, 0.3);
                          return Transform.translate(
                            offset: Offset(120, bounceValue),
                            child: _buildBird(progress, 0.3),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),

                // Loading text
                Text(
                  widget.message ?? 'Loading...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                    shadows: [
                      Shadow(
                        color: Color.fromRGBO(0, 0, 0, 0.2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build all pinwheels at their positions
  List<Widget> _buildPinwheels(Size screenSize) {
    return List.generate(_pinwheelPositions.length, (index) {
      final pos = _pinwheelPositions[index];
      final controller = _pinwheelControllers[index];

      double? top = pos['top'] != null ? screenSize.height * pos['top'] : null;
      double? bottom = pos['bottom'] != null ? screenSize.height * pos['bottom'] : null;
      double? left = pos['left'] != null ? screenSize.width * pos['left'] : null;
      double? right = pos['right'] != null ? screenSize.width * pos['right'] : null;

      // Handle centered positions
      if (pos['centered'] == true) {
        left = screenSize.width * pos['left']! - 60; // 60 is half of pinwheel size
      }
      if (pos['centerY'] == true) {
        top = screenSize.height * pos['top']! - 60;
      }

      return Positioned(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: controller.value * 2 * math.pi * (pos['reverse'] ? -1 : 1),
              child: child,
            );
          },
          child: const Pinwheel(size: 120),
        ),
      );
    });
  }

  /// Calculate bounce animation with delay
  double _calculateBounce(double progress, double delay) {
    final adjustedProgress = (progress + delay) % 1.0;
    return -60 * math.sin(adjustedProgress * math.pi * 2).abs();
  }

  /// Determine if bird should use bird1 (down) or bird2 (up)
  bool _isBirdUp(double progress, double delay) {
    final adjustedProgress = (progress + delay) % 1.0;
    final bounceValue = math.sin(adjustedProgress * math.pi * 2).abs();
    return bounceValue > 0.5;
  }

  /// Build a single bird widget
  Widget _buildBird(double progress, double delay) {
    final isUp = _isBirdUp(progress, delay);
    return Image.asset(
      isUp ? 'assets/images-icons/2.png' : 'assets/images-icons/1.png',
      width: 120,
      height: 120,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.flutter_dash,
          size: 80,
          color: Color(0xFFE91E63),
        );
      },
    );
  }
}

/// Custom painter for geometric diamond pattern
class GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // More visible blue tint for variation
    final lighterBluePaint = Paint()
      ..color = const Color(0xFF9AD9EA).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final slightlyDarkerBluePaint = Paint()
      ..color = const Color(0xFF7AC5DC).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    const spacing = 70.0;

    // Draw subtle diamond grid pattern
    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      for (double x = -spacing; x < size.width + spacing; x += spacing) {
        final path = Path();

        // Create diamond shape
        path.moveTo(x, y - spacing / 2); // Top
        path.lineTo(x + spacing / 2, y); // Right
        path.lineTo(x, y + spacing / 2); // Bottom
        path.lineTo(x - spacing / 2, y); // Left
        path.close();

        // Alternate between subtle blues in checkerboard pattern
        final isLighter = ((x / spacing).floor() + (y / spacing).floor()) % 2 == 0;
        canvas.drawPath(path, isLighter ? lighterBluePaint : slightlyDarkerBluePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pinwheel widget with 5 petals
class Pinwheel extends StatelessWidget {
  final double size;

  const Pinwheel({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: PinwheelPainter(),
      ),
    );
  }
}

/// Custom painter for pinwheel with 5 petals
class PinwheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final petalPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Draw 5 petals - wider and more visible
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72) * math.pi / 180; // 360 / 5 = 72 degrees

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      // Draw wider petal shape
      final path = Path();

      // Start from center
      path.moveTo(0, 0);

      // Left side of petal
      path.cubicTo(
        -10, -10,  // Control point 1 - wider
        -15, -25,  // Control point 2
        -12, -38,  // End point left side
      );

      // Tip of petal (rounded)
      path.cubicTo(
        -8, -42,   // Control point
        8, -42,    // Control point
        12, -38,   // End point right side
      );

      // Right side of petal
      path.cubicTo(
        15, -25,   // Control point
        10, -10,   // Control point
        0, 0,      // Back to center
      );

      path.close();

      canvas.drawPath(path, petalPaint);
      canvas.restore();
    }

    // Draw center circle on top (smaller)
    canvas.drawCircle(center, 18, circlePaint);

    // Add subtle inner circle for depth
    final innerCirclePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12, innerCirclePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


/// Smaller loading widget for use in dialogs or overlays
/// Rectangular popup with grid pattern background and 3 bouncing birds
class LoadingWidget extends StatefulWidget {
  final String? message;
  final double width;
  final double height;

  const LoadingWidget({
    super.key,
    this.message,
    this.width = 400,
    this.height = 280,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final birdSize = widget.height * 0.28;
    final spacing = widget.width * 0.18;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF87CEEB),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Grid pattern background
            Positioned.fill(
              child: CustomPaint(
                painter: GeometricPatternPainter(),
              ),
            ),

            // Main content - centered
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Three birds bouncing
                  SizedBox(
                    height: widget.height * 0.4,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Bird 1 (left)
                        AnimatedBuilder(
                          animation: _bounceController,
                          builder: (context, child) {
                            final progress = _bounceController.value;
                            final bounceValue = _calculateBounce(progress, 0.0, widget.height * 0.1);
                            return Transform.translate(
                              offset: Offset(-spacing, bounceValue),
                              child: _buildSmallBird(birdSize, progress, 0.0),
                            );
                          },
                        ),
                        // Bird 2 (middle)
                        AnimatedBuilder(
                          animation: _bounceController,
                          builder: (context, child) {
                            final progress = _bounceController.value;
                            final bounceValue = _calculateBounce(progress, 0.15, widget.height * 0.1);
                            return Transform.translate(
                              offset: Offset(0, bounceValue),
                              child: _buildSmallBird(birdSize, progress, 0.15),
                            );
                          },
                        ),
                        // Bird 3 (right)
                        AnimatedBuilder(
                          animation: _bounceController,
                          builder: (context, child) {
                            final progress = _bounceController.value;
                            final bounceValue = _calculateBounce(progress, 0.3, widget.height * 0.1);
                            return Transform.translate(
                              offset: Offset(spacing, bounceValue),
                              child: _buildSmallBird(birdSize, progress, 0.3),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: widget.height * 0.06),

                  // Loading text
                  if (widget.message != null)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: widget.width * 0.08),
                      child: Text(
                        widget.message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: widget.height * 0.08,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                          shadows: const [
                            Shadow(
                              color: Color.fromRGBO(0, 0, 0, 0.2),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  double _calculateBounce(double progress, double delay, double amplitude) {
    final adjustedProgress = (progress + delay) % 1.0;
    return -amplitude * math.sin(adjustedProgress * math.pi * 2).abs();
  }

  bool _isSmallBirdUp(double progress, double delay) {
    final adjustedProgress = (progress + delay) % 1.0;
    final bounceValue = math.sin(adjustedProgress * math.pi * 2).abs();
    return bounceValue > 0.5;
  }

  Widget _buildSmallBird(double size, double progress, double delay) {
    final isUp = _isSmallBirdUp(progress, delay);
    return Image.asset(
      isUp ? 'assets/images-icons/2.png' : 'assets/images-icons/1.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.flutter_dash,
          size: size * 0.6,
          color: const Color(0xFFE91E63),
        );
      },
    );
  }
}

/// Helper class for showing loading screens
class LoadingHelper {
  /// Show full screen loading page
  static void showLoadingPage(BuildContext context, {String? message}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) => LoadingPage(message: message),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Show loading dialog overlay with rectangular popup
  static void showLoadingDialog(
      BuildContext context, {
        String? message,
        double width = 400,
        double height = 280,
      }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Center(
        child: LoadingWidget(
          message: message,
          width: width,
          height: height,
        ),
      ),
    );
  }

  /// Hide loading (works for both page and dialog)
  static void hideLoading(BuildContext context) {
    Navigator.of(context).pop();
  }
}