import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'api_service.dart';
import 'loading_page.dart';
import 'login.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool usernameError = false;
  bool passwordError = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _api = ApiService();

  // Same 600px breakpoint as the player-side login screen.
  bool get _isMobile => MediaQuery.of(context).size.width < 600;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {bool hasError = false, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: hasError ? Colors.red : null),
      prefixIcon: Icon(icon, size: 18, color: hasError ? Colors.red : null),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
            color: hasError ? Colors.red : const Color(0xFF046EB8),
            width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.grey,
            width: hasError ? 2 : 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
            color: hasError ? Colors.red : const Color(0xFF046EB8),
            width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    );
  }

  Future<void> _login() async {
    setState(() {
      usernameError = false;
      passwordError = false;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        usernameError = username.isEmpty;
        passwordError = password.isEmpty;
      });
      _showSnackBar('Please enter both username and password.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    LoadingHelper.showLoadingPage(context, message: 'Logging in...');

    final result = await _api.login(username, password);

    if (!mounted) return;

    LoadingHelper.hideLoading(context);
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Merge the token into adminData so every admin page can use it for auth
      final adminData = <String, dynamic>{
        ...?result['admin'] as Map<String, dynamic>?,
        'token': result['token'],
      };
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminDashboard(
            adminData: adminData,
          ),
        ),
      );
    } else {
      setState(() {
        usernameError = true;
        passwordError = true;
      });
      _showSnackBar(
        result['message'] ?? 'Login failed. Please try again.',
        Colors.red,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Same proportions as the player-side login screen.
    final formWidth = _isMobile
        ? screenWidth * 0.79
        : (screenWidth * 0.38).clamp(306.0, 414.0);

    return Scaffold(
      backgroundColor: const Color(0xFF94D2FD),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        toolbarHeight: 48,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              "assets/images-logo/newhomepagelogo.png",
              height: 38,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.book, size: 38, color: Color(0xFF046EB8)),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                onTap: () {
                  // Plain pop() assumes LoginScreen is still sitting under us
                  // on the stack. That's true when you arrived here via the
                  // normal "ADMIN" button (login.dart pushes AdminAuthGate on
                  // top of itself). It's NOT true after a page refresh while
                  // already logged in as admin — main.dart boots straight
                  // into AdminAuthGate in that case, making this the root
                  // route with nothing beneath it, and pop() would land on a
                  // blank screen. Fall back to opening the player login
                  // directly whenever there's nothing real to pop back to.
                  if (Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
                child: Row(
                  children: [
                    Icon(Icons.person,
                        color: const Color(0xFF046EB8),
                        size: _isMobile ? 20 : 16),
                    const SizedBox(width: 4),
                    Text(
                      "PLAYER",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: _isMobile ? 15 : 12,
                        color: const Color(0xFF046EB8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images-icons/background1.png",
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          // Centered content
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images-logo/newloginlogo.png",
                    height: (screenHeight * 0.20).clamp(117.0, 216.0),
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    errorBuilder: (_, __, ___) => Container(
                      height: (screenHeight * 0.20).clamp(117.0, 216.0),
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text(
                          'STARBOOKS\nQUIZ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF046EB8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Login form
                  Container(
                    width: formWidth,
                    padding: EdgeInsets.all(_isMobile ? 18 : 25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Admin",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: _isMobile ? 18 : 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF046EB8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Log In",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: _isMobile ? 12 : 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: _isMobile ? 14 : 18),

                        // Username field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _usernameController,
                              onSubmitted: (_) => _login(),
                              style: const TextStyle(
                                  fontFamily: 'Poppins', fontSize: 12),
                              decoration: _inputDecoration(
                                  "Username", Icons.person,
                                  hasError: usernameError),
                            ),
                            if (usernameError) _buildErrorMessage('Required'),
                          ],
                        ),

                        SizedBox(height: _isMobile ? 10 : 13),

                        // Password field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _passwordController,
                              onSubmitted: (_) => _login(),
                              obscureText: _obscurePassword,
                              style: const TextStyle(
                                  fontFamily: 'Poppins', fontSize: 12),
                              decoration: _inputDecoration(
                                "Password", Icons.lock,
                                hasError: passwordError,
                                suffixIcon: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      size: 18,
                                      color: passwordError ? Colors.red : null,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                              ),
                            ),
                            if (passwordError) _buildErrorMessage('Required'),
                          ],
                        ),

                        SizedBox(height: _isMobile ? 20 : 26),

                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFDD000),
                                foregroundColor: const Color(0xFF816A03),
                                disabledBackgroundColor:
                                const Color(0xFFFDD000).withValues(alpha: 0.6),
                                padding: EdgeInsets.symmetric(
                                    vertical: _isMobile ? 11 : 13),
                                textStyle: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  fontSize: _isMobile ? 13 : 14,
                                ),
                              ),
                              child: const Text("LOG IN"),
                            ),
                          ),
                        ),
                      ],
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

  // ── Error indicator widget — same style as the player-side login ─────────
  Widget _buildErrorMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            message,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}