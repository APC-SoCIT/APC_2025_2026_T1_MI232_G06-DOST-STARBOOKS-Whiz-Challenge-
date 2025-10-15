import 'package:flutter/material.dart';
import 'dart:math';
import 'login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Starbooks Quiz',
      theme: ThemeData(fontFamily: 'Poppins'),
      home: const RegisterPage(),
    );
  }
}

class RegisterPage extends StatefulWidget {
  final Function(String username, String password)? onRegister;

  const RegisterPage({super.key, this.onRegister});

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

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController schoolController = TextEditingController();

  String? selectedAge;
  String? selectedCategory;
  String? selectedSex;

  String? selectedRegionId;
  String? selectedRegionName;
  String? selectedProvinceId;
  String? selectedProvinceName;
  String? selectedCityId;
  String? selectedCityName;

  List<Map<String, String>> regions = [];
  List<Map<String, String>> provinces = [];
  List<Map<String, String>> cities = [];

  static const String baseUrl = 'http://127.0.0.1:8000';

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

    fetchRegions();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _birdController.dispose();
    _avatarController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    schoolController.dispose();
    super.dispose();
  }

  Future<void> fetchRegions() async {
    try {
      final url = Uri.parse('$baseUrl/api/region');
      final resp = await http.get(url, headers: {'Accept': 'application/json'});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final parsed = <Map<String, String>>[];
        for (var e in data) {
          final id = (e['id'] ?? e['_id'] ?? '').toString();
          final name = (e['region_name'] ?? '').toString();
          if (id.isNotEmpty && name.isNotEmpty) {
            parsed.add({'id': id, 'name': name});
          }
        }
        setState(() {
          regions = parsed;
        });
      }
    } catch (e) {
      debugPrint('fetchRegions error: $e');
    }
  }

  Future<void> fetchProvinces(String regionId) async {
    setState(() {
      provinces = [];
      selectedProvinceId = null;
      selectedProvinceName = null;
      cities = [];
      selectedCityId = null;
      selectedCityName = null;
    });
    try {
      final url = Uri.parse('$baseUrl/api/province/$regionId');
      final resp = await http.get(url, headers: {'Accept': 'application/json'});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final parsed = <Map<String, String>>[];
        for (var e in data) {
          final id = (e['id'] ?? e['_id'] ?? '').toString();
          final name = (e['province_name'] ?? '').toString();
          if (id.isNotEmpty && name.isNotEmpty) {
            parsed.add({'id': id, 'name': name});
          }
        }
        setState(() => provinces = parsed);
      }
    } catch (e) {
      debugPrint('fetchProvinces error: $e');
    }
  }

  Future<void> fetchCities(String provinceId) async {
    setState(() {
      cities = [];
      selectedCityId = null;
      selectedCityName = null;
    });
    try {
      final url = Uri.parse('$baseUrl/api/city/$provinceId');
      final resp = await http.get(url, headers: {'Accept': 'application/json'});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final parsed = <Map<String, String>>[];
        for (var e in data) {
          final id = (e['id'] ?? e['_id'] ?? '').toString();
          final name = (e['city_name'] ?? '').toString();
          if (id.isNotEmpty && name.isNotEmpty) {
            parsed.add({'id': id, 'name': name});
          }
        }
        setState(() => cities = parsed);
      }
    } catch (e) {
      debugPrint('fetchCities error: $e');
    }
  }

  Future<void> registerUser() async {
    if (usernameController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        schoolController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill username, password, school")),
      );
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }
    if (selectedRegionId == null ||
        selectedProvinceId == null ||
        selectedCityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please choose Region, Province and City"),
        ),
      );
      return;
    }

    final payload = {
      "username": usernameController.text.trim(),
      "password": passwordController.text,
      "school": schoolController.text.trim(),
      "age": selectedAge ?? "",
      "avatar": selectedAvatar ?? "",
      "category": selectedCategory ?? "",
      "sex": selectedSex ?? "",
      "region": selectedRegionId,
      "province": selectedProvinceId,
      "city": selectedCityId,
    };

    final url = Uri.parse('$baseUrl/api/register');
    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        if (!mounted) return;

        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Registration Successful!",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xDD000000),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Welcome, ${usernameController.text.trim()}!",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Your account has been created successfully. You can now log in to start playing!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Color(0xCF000000),
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (c) => const LogInPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDD000),
                        foregroundColor: const Color(0xFF816A03),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Go to Login",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        String message = resp.body;
        try {
          final jsonBody = jsonDecode(resp.body);
          if (jsonBody is Map && jsonBody['message'] != null) {
            message = jsonBody['message'];
          }
        } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registration failed (${resp.statusCode}): $message"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Check server/CORS.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _regionDropdown() =>
      _buildDropdown("Region", regions, selectedRegionId, (v) {
        setState(() {
          selectedRegionId = v;
          selectedRegionName = regions.firstWhere((r) => r['id'] == v)['name'];
          selectedProvinceId = null;
          selectedProvinceName = null;
          cities = [];
          selectedCityId = null;
          selectedCityName = null;
        });
        if (v != null) fetchProvinces(v);
      });

  Widget _provinceDropdown() =>
      _buildDropdown("Province", provinces, selectedProvinceId, (v) {
        setState(() {
          selectedProvinceId = v;
          selectedProvinceName = provinces.firstWhere(
            (p) => p['id'] == v,
          )['name'];
          selectedCityId = null;
          selectedCityName = null;
        });
        if (v != null) fetchCities(v);
      });

  Widget _cityDropdown() => _buildDropdown("City", cities, selectedCityId, (v) {
    setState(() {
      selectedCityId = v;
      selectedCityName = cities.firstWhere((c) => c['id'] == v)['name'];
    });
  });

  Widget _buildDropdown(
    String label,
    List<Map<String, String>> items,
    String? value,
    void Function(String?)? onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: _inputDecoration(label),
        initialValue: value,
        style: const TextStyle(
          fontSize: 11,
          fontFamily: "Poppins",
          color: Colors.black,
        ),
        items: items.map((e) {
          return DropdownMenuItem(
            value: e['id'],
            child: Text(
              e['name'] ?? e['id'] ?? '',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (step > 0) {
      setState(() {
        step--;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LogInPage()),
      );
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
                color: step >= 1
                    ? const Color(0xFF046EB8)
                    : Colors.grey.shade400,
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

    final Color circleColor = (isActive || isCompleted)
        ? const Color(0xFF046EB8)
        : Colors.grey.shade400;

    return CircleAvatar(radius: 8, backgroundColor: circleColor);
  }

  Widget _buildOutlinedButton(
    String label,
    VoidCallback onPressed, {
    bool isProceed = false,
  }) {
    return OutlinedButton(
      style:
          OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF046EB8), width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.hovered)) {
                return const Color(0xFF046EB8).withAlpha(50);
              }
              return Colors.transparent;
            }),
            foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              return const Color(0xFF046EB8);
            }),
          ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.normal)),
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
          onPressed: registerUser,
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
                  MaterialPageRoute(builder: (context) => const AdminPage()),
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900, minWidth: 400),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
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
              return Transform.translate(offset: Offset(dx, dy), child: child);
            },
            child: Image.asset("assets/images-logo/bird1.png", height: 140),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            "Terms and Conditions",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
            color: Color(0xFF046EB8),
          ),
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
                    backgroundColor: Colors.white,
                    backgroundImage: selectedAvatar != null
                        ? AssetImage(selectedAvatar!)
                        : null,
                    child: selectedAvatar == null
                        ? const Icon(Icons.person, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _buildTextField(
                    Icons.person,
                    "Username",
                    controller: usernameController,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPasswordField(
                          Icons.lock,
                          "Password",
                          hidePassword,
                          (val) => setState(() => hidePassword = !hidePassword),
                          passwordController,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPasswordField(
                          Icons.lock,
                          "Confirm Password",
                          hideConfirmPassword,
                          (val) => setState(
                            () => hideConfirmPassword = !hideConfirmPassword,
                          ),
                          confirmPasswordController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          Icons.school,
                          "School",
                          controller: schoolController,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildAgeDropdown(
                          "Age",
                          onChanged: (v) => setState(() => selectedAge = v),
                        ),
                      ),
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
              child: _buildAvatarDropdown(
                "Avatar",
                icon: Icons.camera_alt,
                onChanged: (value) {
                  setState(() {
                    selectedAvatar = "$value";
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCategoryDropdown(
                "Category",
                onChanged: (v) => setState(() => selectedCategory = v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSexDropdown(
                "Sex",
                onChanged: (v) => setState(() => selectedSex = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _regionDropdown()),
            const SizedBox(width: 10),
            Expanded(child: _provinceDropdown()),
            const SizedBox(width: 10),
            Expanded(child: _cityDropdown()),
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

  Widget _buildTextField(
    IconData icon,
    String hint, {
    bool isPassword = false,
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(fontSize: 12, fontFamily: "Poppins"),
        decoration: _inputDecoration(hint, icon: icon),
      ),
    );
  }

  Widget _buildPasswordField(
    IconData icon,
    String hint,
    bool hide,
    void Function(bool) toggle,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: hide,
        style: const TextStyle(fontSize: 12, fontFamily: "Poppins"),
        decoration: _inputDecoration(hint, icon: icon).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              hide ? Icons.visibility : Icons.visibility_off,
              size: 18,
            ),
            onPressed: () => toggle(!hide),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarDropdown(
    String label, {
    IconData? icon,
    void Function(String?)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        decoration: _inputDecoration(label, icon: icon),
        style: const TextStyle(
          fontSize: 12,
          fontFamily: "Poppins",
          color: Colors.black,
          fontWeight: FontWeight.w400,
        ),
        initialValue: selectedAvatar?.split('/').last.split('.').first,
        items: const [
          DropdownMenuItem(value: "Adventurer", child: Text("Adventurer")),
          DropdownMenuItem(value: "Astronaut", child: Text("Astronaut")),
          DropdownMenuItem(value: "Boy", child: Text("Boy")),
          DropdownMenuItem(value: "Brainy", child: Text("Brainy")),
          DropdownMenuItem(value: "Cool-Monkey", child: Text("Cool-Monkey")),
          DropdownMenuItem(
            value: "Cute-Elephant",
            child: Text("Cute-Elephant"),
          ),
          DropdownMenuItem(value: "Doctor-Boy", child: Text("Doctor-Boy")),
          DropdownMenuItem(value: "Doctor-Girl", child: Text("Doctor-Girl")),
          DropdownMenuItem(value: "Engineer-Boy", child: Text("Engineer-Boy")),
          DropdownMenuItem(
            value: "Engineer-Girl",
            child: Text("Engineer-Girl"),
          ),
          DropdownMenuItem(value: "Girl", child: Text("Girl")),
          DropdownMenuItem(value: "Hacker", child: Text("Hacker")),
          DropdownMenuItem(value: "Leonel", child: Text("Leonel")),
          DropdownMenuItem(
            value: "Scientist-Boy",
            child: Text("Scientist-Boy"),
          ),
          DropdownMenuItem(
            value: "Scientist-Girl",
            child: Text("Scientist-Girl"),
          ),
          DropdownMenuItem(value: "Sly-Fox", child: Text("Sly-Fox")),
          DropdownMenuItem(value: "Sneaky-Snake", child: Text("Sneaky-Snake")),
          DropdownMenuItem(value: "Teacher-Boy", child: Text("Teacher-Boy")),
          DropdownMenuItem(value: "Teacher-Girl", child: Text("Teacher-Girl")),
          DropdownMenuItem(value: "Twirky", child: Text("Twirky")),
          DropdownMenuItem(
            value: "Whiz-Achiever",
            child: Text("Whiz-Achiever"),
          ),
          DropdownMenuItem(value: "Whiz-Busy", child: Text("Whiz-Busy")),
          DropdownMenuItem(value: "Whiz-Happy", child: Text("Whiz-Happy")),
          DropdownMenuItem(value: "Whiz-Ready", child: Text("Whiz-Ready")),
          DropdownMenuItem(value: "Wise-Turtle", child: Text("Wise-Turtle")),
        ],
        onChanged: (value) {
          setState(() {
            switch (value) {
              case "Adventurer":
                selectedAvatar = "assets/images-avatars/Adventurer.png";
                break;
              case "Astronaut":
                selectedAvatar = "assets/images-avatars/Astronaut.png";
                break;
              case "Boy":
                selectedAvatar = "assets/images-avatars/Boy.png";
                break;
              case "Brainy":
                selectedAvatar = "assets/images-avatars/Brainy.png";
                break;
              case "Cool-Monkey":
                selectedAvatar = "assets/images-avatars/Cool-Monkey.png";
                break;
              case "Cute-Elephant":
                selectedAvatar = "assets/images-avatars/Cute-Elephant.png";
                break;
              case "Doctor-Boy":
                selectedAvatar = "assets/images-avatars/Doctor-Boy.png";
                break;
              case "Doctor-Girl":
                selectedAvatar = "assets/images-avatars/Doctor-Girl.png";
                break;
              case "Engineer-Boy":
                selectedAvatar = "assets/images-avatars/Engineer-Boy.png";
                break;
              case "Engineer-Girl":
                selectedAvatar = "assets/images-avatars/Engineer-Girl.png";
                break;
              case "Girl":
                selectedAvatar = "assets/images-avatars/Girl.png";
                break;
              case "Hacker":
                selectedAvatar = "assets/images-avatars/Hacker.png";
                break;
              case "Leonel":
                selectedAvatar = "assets/images-avatars/Leonel.png";
                break;
              case "Scientist-Boy":
                selectedAvatar = "assets/images-avatars/Scientist-Boy.png";
                break;
              case "Scientist-Girl":
                selectedAvatar = "assets/images-avatars/Scientist-Girl.png";
                break;
              case "Sly-Fox":
                selectedAvatar = "assets/images-avatars/Sly-Fox.png";
                break;
              case "Sneaky-Snake":
                selectedAvatar = "assets/images-avatars/Sneaky-Snake.png";
                break;
              case "Teacher-Boy":
                selectedAvatar = "assets/images-avatars/Teacher-Boy.png";
                break;
              case "Teacher-Girl":
                selectedAvatar = "assets/images-avatars/Teacher-Girl.png";
                break;
              case "Twirky":
                selectedAvatar = "assets/images-avatars/Twirky.png";
                break;
              case "Whiz-Achiever":
                selectedAvatar = "assets/images-avatars/Whiz-Achiever.png";
                break;
              case "Whiz-Busy":
                selectedAvatar = "assets/images-avatars/Whiz-Busy.png";
                break;
              case "Whiz-Happy":
                selectedAvatar = "assets/images-avatars/Whiz-Happy.png";
                break;
              case "Whiz-Ready":
                selectedAvatar = "assets/images-avatars/Whiz-Ready.png";
                break;
              case "Wise-Turtle":
                selectedAvatar = "assets/images-avatars/Wise-Turtle.png";
                break;
            }
          });
        },
      ),
    );
  }

  Widget _buildAgeDropdown(
    String label, {
    IconData? icon,
    void Function(String?)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        decoration: _inputDecoration(label, icon: icon),
        style: const TextStyle(
          fontSize: 12,
          fontFamily: "Poppins",
          color: Colors.black,
          fontWeight: FontWeight.w400,
        ),
        items: const [
          DropdownMenuItem(
            value: "0-12",
            child: Text("0-12", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "13-17",
            child: Text("13-17", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "18-22",
            child: Text("18-22", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "23-29",
            child: Text("23-29", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "30-39",
            child: Text("30-39", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "40+",
            child: Text("40+", style: TextStyle(fontSize: 12)),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCategoryDropdown(
    String label, {
    IconData? icon,
    void Function(String?)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        decoration: _inputDecoration(label, icon: icon),
        style: const TextStyle(
          fontSize: 12,
          fontFamily: "Poppins",
          color: Colors.black,
          fontWeight: FontWeight.w400,
        ),
        items: const [
          DropdownMenuItem(
            value: "Student",
            child: Text("Student", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "Government Employee",
            child: Text("Government Employee", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "Private Employee",
            child: Text("Private Employee", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "Self-Employed",
            child: Text("Self-Employed", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "Not Employed",
            child: Text("Not Employed", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "Others",
            child: Text("Others", style: TextStyle(fontSize: 12)),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSexDropdown(
    String label, {
    IconData? icon,
    void Function(String?)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        decoration: _inputDecoration(label, icon: icon),
        style: const TextStyle(
          fontSize: 12,
          fontFamily: "Poppins",
          color: Colors.black,
          fontWeight: FontWeight.w400,
        ),
        items: const [
          DropdownMenuItem(
            value: "Male",
            child: Text("Male", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "Female",
            child: Text("Female", style: TextStyle(fontSize: 12)),
          ),
        ],
        onChanged: onChanged,
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
