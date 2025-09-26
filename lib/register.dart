import 'package:flutter/material.dart';
import 'dart:math';
import 'login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Starbooks Quiz',
      home: RegisterPage(),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  int step = 0;
  late final AnimationController _backgroundController;
  late final AnimationController _birdController;
  late final AnimationController _avatarController;
  String? selectedAvatar;

  bool hidePassword = true;
  bool hideConfirmPassword = true;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 35),
    )..repeat();

    _birdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _birdController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  void _handleBack(BuildContext context) {
    if (step > 0) {
      setState(() {
        step--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildStepper() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildStepCircle(0),
            Expanded(
              child: Container(
                height: 2,
                color:
                step >= 1 ? const Color(0xFF046EB8) : Colors.grey.shade400,
              ),
            ),
            _buildStepCircle(1),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              "Privacy Notice",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              "Account Setup",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepCircle(int stepIndex) {
    final bool isCompleted = step > stepIndex;
    final bool isActive = step == stepIndex;

    final Color circleColor =
    (isActive || isCompleted) ? const Color(0xFF046EB8) : Colors.grey.shade400;

    return CircleAvatar(
      radius: 8,
      backgroundColor: circleColor,
    );
  }

  Widget _buildOutlinedButton(String label, VoidCallback onPressed,
      {bool isProceed = false}) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF046EB8), width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFF046EB8).withAlpha(50); // fixed hover opacity
            }
            return Colors.transparent;
          },
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color>(
              (states) {
            return const Color(0xFF046EB8);
          },
        ),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPrivacyStepButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildOutlinedButton("Back", () => _handleBack(context)),
        _buildOutlinedButton("Proceed", () {
          setState(() {
            step = 1;
          });
        }, isProceed: true),
      ],
    );
  }

  Widget _buildAccountSetupStepButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildOutlinedButton("Back", () => _handleBack(context)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFDD000),
            foregroundColor: const Color(0xFFAC8337),
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LogInPage()),
            );
          },
          child: const Text(
            "REGISTER",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF94D2FD),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset("assets/images-logo/starbookslogo.png", height: 50),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminPage(),
                  ),
                );
              },
              child: Row(
                children: const [
                  Icon(Icons.person, color: Color(0xFF046EB8)),
                  SizedBox(width: 5),
                  Text(
                    "ADMIN",
                    style: TextStyle(
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
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              final offset = (_backgroundController.value * screenWidth);
              return Stack(
                children: [
                  Positioned(
                    left: offset % screenWidth - screenWidth,
                    top: 0,
                    child: Image.asset(
                      "assets/images-icons/background1.png",
                      width: screenWidth,
                      height: screenHeight,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    left: offset % screenWidth,
                    top: 0,
                    child: Image.asset(
                      "assets/images-icons/background1.png",
                      width: screenWidth,
                      height: screenHeight,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              );
            },
          ),
          Center(
            child: Container(
              width: 800,
              height: 520,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildStepper(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: step == 0
                          ? _buildPrivacyStepContent()
                          : _buildAccountSetupStepContent(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  step == 0
                      ? _buildPrivacyStepButtons(context)
                      : _buildAccountSetupStepButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            "Register",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF046EB8),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: AnimatedBuilder(
            animation: _birdController,
            builder: (context, child) {
              final dx = 15 * sin(_birdController.value * 2 * pi);
              final dy = 15 * cos(_birdController.value * 2 * pi);
              return Transform.translate(
                offset: Offset(dx, dy),
                child: child,
              );
            },
            child: Image.asset(
              "assets/images-logo/bird1.png",
              height: 140,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            "Terms and Conditions",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "By accessing STARBOOKS WHIZ CHALLENGE, you agree to these terms and conditions. "
              "We collect personal information and usage data to improve our services and efficiency. "
              "We prioritize data security and do not share personal information with third parties without consent, "
              "except as required by law. Users must provide accurate information and comply with all laws while using our site. "
              "For questions, contact us at support@starbookswhizbee.com",
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildAccountSetupStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Register",
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF046EB8)),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 20, top: 10),
              child: AnimatedBuilder(
                animation: _avatarController,
                builder: (context, child) {
                  final dy = 3 * sin(_avatarController.value * 2 * pi);
                  final dx = 3 * cos(_avatarController.value * 2 * pi);
                  return Transform.translate(
                    offset: Offset(dx, dy),
                    child: child,
                  );
                },
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: const Color(0xFFFDD000),
                  child: CircleAvatar(
                    radius: 75,
                    backgroundImage: selectedAvatar != null
                        ? AssetImage(selectedAvatar!)
                        : null,
                    backgroundColor: Colors.white,
                    child: selectedAvatar == null
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _buildTextField(Icons.person, "Username"),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPasswordField(
                            Icons.lock, "Password", hidePassword, (val) {
                          setState(() {
                            hidePassword = !hidePassword;
                          });
                        }),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPasswordField(
                            Icons.lock, "Confirm Password", hideConfirmPassword,
                                (val) {
                              setState(() {
                                hideConfirmPassword = !hideConfirmPassword;
                              });
                            }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(Icons.school, "School")),
                      const SizedBox(width: 10),
                      Expanded(child: _buildDropdown("Age")),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
                child: _buildDropdown("Avatar",
                    icon: Icons.camera_alt, onChanged: (value) {
                      setState(() {
                        selectedAvatar = "assets/avatars/avatar${value}.png";
                      });
                    })),
            const SizedBox(width: 10),
            Expanded(child: _buildDropdown("Category")),
            const SizedBox(width: 10),
            Expanded(child: _buildDropdown("Sex")),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildDropdown("Region")),
            const SizedBox(width: 10),
            Expanded(child: _buildDropdown("Province")),
            const SizedBox(width: 10),
            Expanded(child: _buildDropdown("City")),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, fontFamily: "Poppins"),
      prefixIcon: icon != null ? Icon(icon, size: 18) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF046EB8), width: 2),
      ),
    );
  }

  Widget _buildTextField(IconData icon, String hint,
      {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        obscureText: isPassword,
        style: const TextStyle(fontSize: 12, fontFamily: "Poppins"),
        decoration: _inputDecoration(hint, icon: icon),
      ),
    );
  }

  Widget _buildPasswordField(
      IconData icon, String hint, bool hide, void Function(bool) toggle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        obscureText: hide,
        style: const TextStyle(fontSize: 12, fontFamily: "Poppins"),
        decoration: _inputDecoration(hint, icon: icon).copyWith(
          suffixIcon: IconButton(
            icon:
            Icon(hide ? Icons.visibility : Icons.visibility_off, size: 18),
            onPressed: () => toggle(!hide),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label,
      {IconData? icon, void Function(String?)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        decoration: _inputDecoration(label, icon: icon),
        style: const TextStyle(
            fontSize: 12,
            fontFamily: "Poppins",
            color: Colors.black,
            fontWeight: FontWeight.w400),
        items: const [
          DropdownMenuItem(
              value: "1",
              child: Text("Option 1", style: TextStyle(fontSize: 12))),
          DropdownMenuItem(
              value: "2",
              child: Text("Option 2", style: TextStyle(fontSize: 12))),
        ],
        onChanged: onChanged ?? (value) {},
      ),
    );
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Panel")),
      body: const Center(
        child: Text("This is the Admin Page (to be implemented)."),
      ),
    );
  }
}
