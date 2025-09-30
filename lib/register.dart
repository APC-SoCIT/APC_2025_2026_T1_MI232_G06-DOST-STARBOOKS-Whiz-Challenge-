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
  // UI state & controllers (kept your original UI)
  int step = 0;
  late final AnimationController _backgroundController;
  late final AnimationController _birdController;
  late final AnimationController _avatarController;
  String? selectedAvatar;

  bool hidePassword = true;
  bool hideConfirmPassword = true;

  // Controllers for inputs
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController schoolController = TextEditingController();

  // Dropdown selections & lists
  String? selectedAge;
  String? selectedCategory;
  String? selectedSex;

  // For region/province/city we will store the selected id (string) and display name separately
  String? selectedRegionId;
  String? selectedRegionName;
  String? selectedProvinceId;
  String? selectedProvinceName;
  String? selectedCityId;
  String? selectedCityName;

  List<Map<String, String>> regions = [];
  List<Map<String, String>> provinces = [];
  List<Map<String, String>> cities = [];

  bool loadingRegions = false;
  bool loadingProvinces = false;
  bool loadingCities = false;

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

    // Fetch regions at startup
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

  // --------------------------
  // API: Fetchers for dropdowns
  // --------------------------
  Future<void> fetchRegions() async {
    setState(() => loadingRegions = true);
    try {
      final url = Uri.parse('$baseUrl/api/region');
      final resp = await http.get(url, headers: {'Accept': 'application/json'});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        // Expecting array of {id: "...", region_name: "..."}
        final parsed = <Map<String, String>>[];
        for (var e in data) {
          final id = (e['id'] ?? e['_id'] ?? '').toString();
          final name = (e['region_name'] ?? e['name'] ?? '').toString();
          if (id.isNotEmpty) parsed.add({'id': id, 'name': name});
        }
        setState(() {
          regions = parsed;
        });
      } else {
        debugPrint('fetchRegions failed: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('fetchRegions error: $e');
    } finally {
      setState(() => loadingRegions = false);
    }
  }

  Future<void> fetchProvinces(String regionId) async {
    setState(() {
      loadingProvinces = true;
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
          final name = (e['province_name'] ?? e['name'] ?? '').toString();
          if (id.isNotEmpty && name.isNotEmpty) {
            parsed.add({'id': id, 'name': name});
          }
        }
        setState(() {
          provinces = parsed;
        });
      } else {
        debugPrint('fetchProvinces failed: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('fetchProvinces error: $e');
    } finally {
      setState(() => loadingProvinces = false);
    }
  }

  Future<void> fetchCities(String provinceId) async {
    setState(() {
      loadingCities = true;
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
      } else {
        debugPrint('fetchCities failed: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('fetchCities error: $e');
    } finally {
      setState(() => loadingCities = false);
    }
  }

  // --------------------------
  // POST register
  // --------------------------
  Future<void> registerUser() async {
    // Basic front-end validation
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
        debugPrint('Registered OK: ${resp.body}');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => const LogInPage()),
        );
      } else {
        debugPrint('Register failed: ${resp.statusCode} ${resp.body}');
        final body = resp.body;
        String message = 'Registration failed';
        try {
          final jsonBody = jsonDecode(body);
          if (jsonBody is Map && jsonBody['message'] != null) {
            message = jsonBody['message'].toString();
          } else if (jsonBody is Map && jsonBody['errors'] != null) {
            message = jsonBody['errors'].toString();
          } else {
            message = body;
          }
        } catch (_) {
          message = body;
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registration failed (${resp.statusCode}): $message"),
          ),
        );
      }
    } catch (e) {
      debugPrint('registerUser error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Check server/CORS.')),
      );
    }
  }

  // --------------------------
  // UI helpers for dynamic dropdowns
  // --------------------------
  Widget _regionDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: loadingRegions
          ? const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            )
          : DropdownButtonFormField<String>(
              decoration: _inputDecoration('Region'),
              initialValue: selectedRegionId,
              items: regions
                  .map(
                    (r) => DropdownMenuItem(
                      value: r['id'],
                      child: Text(r['name'] ?? r['id'] ?? ''),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedRegionId = v;
                  selectedRegionName = regions.firstWhere(
                    (r) => r['id'] == v,
                  )['name'];
                });
                if (v != null) fetchProvinces(v);
              },
            ),
    );
  }

  Widget _provinceDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: loadingProvinces
          ? const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            )
          : DropdownButtonFormField<String>(
              decoration: _inputDecoration('Province'),
              initialValue: selectedProvinceId,
              items: provinces
                  .map(
                    (p) => DropdownMenuItem(
                      value: p['id'],
                      child: Text(p['name'] ?? p['id'] ?? ''),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedProvinceId = v;
                  selectedProvinceName = provinces.firstWhere(
                    (p) => p['id'] == v,
                  )['name'];
                });
                if (v != null) fetchCities(v);
              },
            ),
    );
  }

  Widget _cityDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: loadingCities
          ? const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            )
          : DropdownButtonFormField<String>(
              decoration: _inputDecoration('City'),
              initialValue: selectedCityId,
              items: cities
                  .map(
                    (c) => DropdownMenuItem(
                      value: c['id'],
                      child: Text(c['name'] ?? c['id'] ?? ''),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedCityId = v;
                  selectedCityName = cities.firstWhere(
                    (c) => c['id'] == v,
                  )['name'];
                });
              },
            ),
    );
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
                    backgroundImage: selectedAvatar != null
                        ? AssetImage(selectedAvatar!)
                        : null,
                    backgroundColor: Colors.white,
                    child: selectedAvatar == null
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          )
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
                        child: _buildDropdown(
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
              child: _buildDropdown(
                "Avatar",
                icon: Icons.camera_alt,
                onChanged: (value) {
                  setState(() {
                    selectedAvatar = "assets/avatars/avatar${value}.png";
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDropdown(
                "Category",
                onChanged: (v) => setState(() => selectedCategory = v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDropdown(
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

  Widget _buildDropdown(
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
            value: "1",
            child: Text("Option 1", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "2",
            child: Text("Option 2", style: TextStyle(fontSize: 12)),
          ),
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
