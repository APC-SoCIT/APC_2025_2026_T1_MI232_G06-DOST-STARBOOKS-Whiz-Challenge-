import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'register.dart';
import 'homepage.dart';
import 'admin_login.dart';
import 'loading_page.dart';
import 'audio_service.dart';  // ✅ Use AudioService instead of FlameAudio directly
import 'session_manager.dart'; // ✅ Save session on login so refresh skips splash screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _obscurePassword = true;
  bool usernameError = false;
  bool passwordError = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final String baseUrl = 'http://localhost:8000';
  final AudioService _audioService = AudioService();  // ✅ Use AudioService

  late AnimationController _buttonScaleController;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();

    // ✅ Ensure homepage music continues playing
    _audioService.playHomepageMusic();

    // Button scale animation for press effect
    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _buttonScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _buttonScaleController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _buttonScaleController.dispose();
    super.dispose();
  }

  void _playClickSound() async {
    await _audioService.playClickSound();
  }

  InputDecoration _inputDecoration(String label, IconData icon, {bool hasError = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        color: hasError ? Colors.red : null,
      ),
      prefixIcon: Icon(icon, color: hasError ? Colors.red : null),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: hasError ? Colors.red : const Color(0xFF046EB8),
          width: 2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: hasError ? Colors.red : Colors.grey,
          width: hasError ? 2 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: hasError ? Colors.red : const Color(0xFF046EB8),
          width: 2,
        ),
      ),
    );
  }

  void _goToRegister() {
    _playClickSound();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterPage(),
      ),
    );
  }

  Future<void> _login() async {
    _playClickSound();

    await _buttonScaleController.forward();
    await _buttonScaleController.reverse();

    // Clear previous errors
    setState(() {
      usernameError = false;
      passwordError = false;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // Validation
    if (username.isEmpty && password.isNotEmpty) {
      if (!mounted) return;
      setState(() => usernameError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password.isEmpty && username.isNotEmpty) {
      if (!mounted) return;
      setState(() => passwordError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (username.isEmpty && password.isEmpty) {
      if (!mounted) return;
      setState(() {
        usernameError = true;
        passwordError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (username.length < 3) {
      if (!mounted) return;
      setState(() => usernameError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username must be at least 3 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (username.length > 20) {
      if (!mounted) return;
      setState(() => usernameError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username exceeds maximum length'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ SHOW FULL PAGE LOADING - User passed all validations, now logging in
    if (!mounted) return;
    LoadingHelper.showLoadingPage(context, message: 'Logging in...');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      // ✅ HIDE LOADING before showing any dialogs or navigating
      if (mounted) LoadingHelper.hideLoading(context);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        final userId = data['user']['id']?.toString() ??
            data['user']['_id']?.toString() ?? '';

        // Check if this is the user's first login - use tutorial completion key
        // so it survives logout (prefs.clear() wipes first_login but we check tutorial separately)
        final prefs = await SharedPreferences.getInstance();
        final tutorialCompletedKey = 'main_tutorial_completed_$userId';
        final bool tutorialAlreadyCompleted = prefs.getBool(tutorialCompletedKey) ?? false;
        final bool isFirstLogin = !tutorialAlreadyCompleted;

        // Check if widget is still mounted before navigation
        if (!mounted) return;

        // ✅ Build the profile object once so we can both save it and pass it
        final profile = UserProfile(
          id: userId,
          username: data['user']['username'],
          school: data['user']['school'] ?? 'Unknown School',
          age: data['user']['age']?.toString() ?? 'N/A',
          category: data['user']['category'] ?? 'Student',
          sex: data['user']['sex'] ?? 'N/A',
          region: data['user']['region']?.toString() ?? '',
          province: data['user']['province']?.toString() ?? '',
          city: data['user']['city']?.toString() ?? '',
          avatar: data['user']['avatar'] ?? 'default',
        );

        // ✅ Persist session so a page refresh goes straight to HomePage
        await SessionManager.saveSession(profile);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              profile: profile,
              isNewUser: isFirstLogin,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        setState(() {
          usernameError = true;
          passwordError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Invalid username or password. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // ✅ HIDE LOADING on error
      if (mounted) LoadingHelper.hideLoading(context);

      if (!mounted) return;
      setState(() {
        usernameError = true;
        passwordError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to server: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _buttonScaleController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF94D2FD),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  "assets/images-logo/newhomepagelogo.png",
                  height: 50,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                ),
                InkWell(
                  onTap: () {
                    _playClickSound();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminLoginPage()),
                    );
                  },
                  child: Row(
                    children: const [
                      Icon(Icons.person, color: Color(0xFF046EB8)),
                      SizedBox(width: 5),
                      Text(
                        "ADMIN",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF046EB8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              Image.asset(
                "assets/images-icons/background1.png",
                width: screenWidth,
                height: screenHeight,
                fit: BoxFit.cover,
              ),
              Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/images-logo/newloginlogo.png",
                          height: 170,
                          filterQuality: FilterQuality.high,
                          isAntiAlias: true,
                        ),
                        const SizedBox(height: 10),

                        Container(
                          width: 380,
                          padding: const EdgeInsets.all(28.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Log In",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF046EB8),
                                ),
                              ),
                              const SizedBox(height: 20),

                              TextField(
                                controller: _usernameController,
                                onSubmitted: (_) => _login(),
                                decoration: _inputDecoration("Username", Icons.person, hasError: usernameError),
                              ),
                              const SizedBox(height: 15),

                              TextField(
                                controller: _passwordController,
                                onSubmitted: (_) => _login(),
                                obscureText: _obscurePassword,
                                decoration: _inputDecoration("Password", Icons.lock, hasError: passwordError).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: passwordError ? Colors.red : null,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),

                              Transform.scale(
                                scale: _buttonScale.value,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFDD000),
                                      foregroundColor: const Color(0xFF816A03),
                                      textStyle: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    child: const Text("LOG IN"),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "No account yet? ",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: _goToRegister,
                                    child: const Text(
                                      "Register here",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 10,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}