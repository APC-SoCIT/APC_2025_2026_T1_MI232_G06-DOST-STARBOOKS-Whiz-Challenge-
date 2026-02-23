import 'package:flutter/material.dart';
import 'login.dart';
import 'dart:math' as math;
import 'audio_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _starsController;
  late AnimationController _logoController;
  late AnimationController _logoTextController;
  late AnimationController _buttonController;
  late AnimationController _buttonScaleController;
  late AnimationController _starbooksController;
  late AnimationController _waveFlowController;
  late AnimationController _transitionController;

  bool _showStars = false;
  bool _showLogo = false;
  bool _showLogoText = false;
  bool _showButton = false;
  bool _showStarbooks = false;
  bool _isTransitioning = false;

  final List<StarData> _stars = [];
  final math.Random _random = math.Random();
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();

    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() { if (mounted) setState(() {}); });

    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _logoTextController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _buttonController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _buttonScaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _starbooksController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    // Continuous wave flow — loops independently
    _waveFlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    // Transition progress 0→1
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _startAnimationSequence());
  }

  @override
  void dispose() {
    _starsController.dispose();
    _logoController.dispose();
    _logoTextController.dispose();
    _buttonController.dispose();
    _buttonScaleController.dispose();
    _starbooksController.dispose();
    _waveFlowController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  void _generateStars() {
    for (int i = 0; i < 40; i++) {
      _stars.add(StarData(
        xPosition: _random.nextDouble() * 100,
        yPosition: _random.nextDouble() * 100,
        size: _random.nextDouble() * 4 + 1.5,
        twinkleOffset: _random.nextDouble() * 2 * math.pi,
      ));
    }
  }

  void _startAnimationSequence() async {
    _generateStars();
    setState(() => _showStars = true);
    _starsController.repeat(reverse: true);

    // Text slides in first
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _showLogoText = true);
    await _logoTextController.forward();

    // Then logo pops out
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _showLogo = true);
    await _logoController.forward();

    // Then start button
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() => _showButton = true);
    await _buttonController.forward();
  }

  Animation<double> _getPopAnimation(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOut)), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 40),
    ]).animate(controller);
  }

  void goToLogin() async {
    if (_isTransitioning) return;
    setState(() => _isTransitioning = true);

    // Start music immediately on tap — satisfies browser autoplay policy
    _audioService.playHomepageMusic();
    _audioService.playClickSound();

    await _buttonScaleController.forward();
    await _buttonScaleController.reverse();

    if (!mounted) return;

    // Animate wave transition, then swap to login with no loading screen
    _transitionController.forward();
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        pageBuilder: (context, _, __) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Pre-render login underneath so it appears instantly after wave clears
          if (_isTransitioning) const LoginScreen(),

          // Splash screen with animated wave clip
          AnimatedBuilder(
            animation: Listenable.merge([_transitionController, _waveFlowController]),
            builder: (context, _) {
              final progress = CurvedAnimation(
                parent: _transitionController,
                curve: Curves.easeInOutCubic,
              ).value;
              return ClipPath(
                clipper: WaveRevealClipper(progress, _waveFlowController.value),
                child: _buildSplashContent(screenWidth, screenHeight),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSplashContent(double screenWidth, double screenHeight) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/splashscreen/final_background.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF001F3F), Color(0xFF0A4D8C), Color(0xFF4A9FD8)],
                ),
              ),
            ),
          ),
        ),

        if (_showStars)
          RepaintBoundary(
            child: Stack(
              children: _stars.map((star) {
                final twinkle = math.sin(_starsController.value * 2 * math.pi + star.twinkleOffset);
                final opacity = 0.3 + (twinkle * 0.4);
                return Positioned(
                  left: (star.xPosition / 100) * screenWidth,
                  top: (star.yPosition / 100) * screenHeight,
                  child: Container(
                    width: star.size,
                    height: star.size,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.3 * opacity), blurRadius: star.size, spreadRadius: star.size * 0.3)],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),


        Positioned(
          bottom: 20, right: 20,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'by ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 4),
              Image.asset('assets/splashscreen/starbooks.png', height: 38,
                errorBuilder: (_, __, ___) => const Text('STARBOOKS',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Text slides in from left FIRST — big and wide
              if (_showLogoText)
                AnimatedBuilder(
                  animation: _logoTextController,
                  builder: (context, child) {
                    final slide = Tween<Offset>(
                      begin: const Offset(-1.5, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: _logoTextController, curve: Curves.easeOutCubic));
                    return SlideTransition(
                      position: slide,
                      child: Opacity(
                        opacity: _logoTextController.value.clamp(0.0, 1.0),
                        child: Image.asset(
                          'assets/splashscreen/starbooksfinaltext2.png',
                          width: 780,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text(
                            'STARBOOKS WHIZ\nCHALLENGE',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white,
                                shadows: [Shadow(color: Colors.black45, offset: Offset(2, 2), blurRadius: 4)]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              // Logo pops out second
              if (_showLogo)
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    final animation = _getPopAnimation(_logoController);
                    return Transform.scale(
                      scale: animation.value,
                      child: Opacity(
                        opacity: _logoController.value,
                        child: Image.asset('assets/splashscreen/logo.png', height: 320,
                          errorBuilder: (_, __, ___) => Container(
                            height: 320, width: 320,
                            decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.3), shape: BoxShape.circle),
                            child: const Icon(Icons.star, size: 150, color: Colors.amber),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),
              // START button fades in last
              if (_showButton)
                AnimatedBuilder(
                  animation: Listenable.merge([_buttonController, _buttonScaleController]),
                  builder: (context, child) {
                    final buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
                        CurvedAnimation(parent: _buttonScaleController, curve: Curves.easeInOut));
                    return FadeTransition(
                      opacity: _buttonController,
                      child: Transform.scale(
                        scale: buttonScale.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: const Color(0xFFFDD000).withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2)],
                          ),
                          child: ElevatedButton(
                            onPressed: _isTransitioning ? null : goToLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFDD000),
                              foregroundColor: const Color(0xFF816A03),
                              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 4,
                            ),
                            child: const Text('START', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class StarData {
  final double xPosition;
  final double yPosition;
  final double size;
  final double twinkleOffset;

  StarData({
    required this.xPosition,
    required this.yPosition,
    required this.size,
    required this.twinkleOffset,
  });
}

// Wave takes TWO separate values: progress (height) + wavePhase (flow)
// This lets the wave animate sideways continuously while also rising
class WaveRevealClipper extends CustomClipper<Path> {
  final double progress;   // 0→1: how far up the screen has been revealed
  final double wavePhase;  // 0→1 looping: drives sideways wave motion

  WaveRevealClipper(this.progress, this.wavePhase);

  @override
  Path getClip(Size size) {
    final path = Path();

    if (progress <= 0) {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }
    if (progress >= 1.0) return path;

    final remainingHeight = size.height * (1 - progress);
    // Amplitude shrinks as wave approaches top
    final waveAmplitude = 40.0 * (1 - progress * 0.8);
    const frequency = 3.5;

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, remainingHeight);

    for (double x = size.width; x >= 0; x -= 2) {
      final normalizedX = x / size.width;
      // wavePhase drives sideways flow completely independently of progress
      final waveOffset = math.sin(
        normalizedX * math.pi * 2 * frequency - wavePhase * math.pi * 2,
      ) * waveAmplitude;
      final y = (remainingHeight + waveOffset).clamp(0.0, size.height);
      path.lineTo(x, y);
    }

    path.lineTo(0, remainingHeight);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(WaveRevealClipper oldClipper) =>
      oldClipper.progress != progress || oldClipper.wavePhase != wavePhase;
}