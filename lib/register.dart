import 'audio_service.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'loading_page.dart'; // ✅ ADDED: Loading screen

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  int step = 0; // 0 = Privacy, 1 = Personal Info, 2 = School & Location

  // Controllers
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController schoolController = TextEditingController();

  // Form selections
  String? selectedAvatar;
  String? selectedAge;
  String? selectedCategory;
  String? selectedStudentCategory;
  String? selectedSex;
  String? selectedRegionId;
  String? selectedProvinceId;
  String? selectedCityId;
  String? selectedRegionName;
  String? selectedProvinceName;
  String? selectedCityName;

  // Error tracking for ALL fields
  bool usernameError = false;
  bool passwordError = false;
  bool confirmPasswordError = false;
  bool schoolError = false;
  bool ageError = false;
  bool avatarError = false;
  bool categoryError = false;
  bool studentCategoryError = false;
  bool sexError = false;
  bool regionError = false;
  bool provinceError = false;
  bool cityError = false;

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool _hasFormChanged = false;

  List<Map<String, String>> region = [];
  List<Map<String, String>> province = [];
  List<Map<String, String>> city = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _buttonScaleController;
  late Animation<double> _buttonScale;

  static const String baseUrl = 'http://localhost:8000';

  @override
  void initState() {
    super.initState();

    // Add listeners to track changes
    usernameController.addListener(() => setState(() => _hasFormChanged = true));
    passwordController.addListener(() => setState(() => _hasFormChanged = true));
    confirmPasswordController.addListener(() => setState(() => _hasFormChanged = true));
    schoolController.addListener(() => setState(() => _hasFormChanged = true));

    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonScaleController, curve: Curves.easeInOut),
    );

    fetchRegions();
    _fadeController.forward();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    schoolController.dispose();
    _fadeController.dispose();
    _buttonScaleController.dispose();
    super.dispose();
  }

  // Helper method to clear all errors
  void _clearErrors() {
    setState(() {
      usernameError = false;
      passwordError = false;
      confirmPasswordError = false;
      schoolError = false;
      ageError = false;
      avatarError = false;
      categoryError = false;
      studentCategoryError = false;
      sexError = false;
      regionError = false;
      provinceError = false;
      cityError = false;
    });
  }

  void _playClickSound() async {
    try {
      await AudioService().playClickSound();
    } catch (e) {
      debugPrint('Click sound error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String? _validateUsername(String username) {
    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (username.length > 20) {
      return 'Username must not exceed 20 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  String? _validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  String? _validateSchool(String school) {
    if (school.length < 3) {
      return 'School name must be at least 3 characters';
    }
    if (school.length > 100) {
      return 'School name is too long';
    }
    return null;
  }

  bool _validateStep1() {
    _clearErrors();
    bool hasError = false;

    if (usernameController.text.trim().isEmpty) {
      setState(() => usernameError = true);
      hasError = true;
    }
    if (passwordController.text.isEmpty) {
      setState(() => passwordError = true);
      hasError = true;
    }
    if (confirmPasswordController.text.isEmpty) {
      setState(() => confirmPasswordError = true);
      hasError = true;
    }
    if (selectedAge == null) {
      setState(() => ageError = true);
      hasError = true;
    }
    if (selectedSex == null) {
      setState(() => sexError = true);
      hasError = true;
    }
    if (selectedAvatar == null) {
      setState(() => avatarError = true);
      hasError = true;
    }

    if (hasError) {
      _showError('Please fill in all required fields');
      return false;
    }

    String? usernameErrorMsg = _validateUsername(usernameController.text);
    if (usernameErrorMsg != null) {
      setState(() => usernameError = true);
      _showError(usernameErrorMsg);
      return false;
    }

    String? passwordErrorMsg = _validatePassword(passwordController.text);
    if (passwordErrorMsg != null) {
      setState(() => passwordError = true);
      _showError(passwordErrorMsg);
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        passwordError = true;
        confirmPasswordError = true;
      });
      _showError('Passwords do not match');
      return false;
    }

    return true;
  }

  void _showAvatarPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Choose Your Avatar",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF046EB8),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 400,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: _getAvatarList().length,
                  itemBuilder: (context, index) {
                    final avatarName = _getAvatarList()[index];
                    final avatarPath = "assets/images-avatars/$avatarName.png";
                    final isSelected = selectedAvatar == avatarPath;

                    return _AvatarGridItem(
                      avatarName: avatarName,
                      avatarPath: avatarPath,
                      isSelected: isSelected,
                      onTap: () {
                        _playClickSound();
                        setState(() {
                          selectedAvatar = avatarPath;
                          avatarError = false;
                          _hasFormChanged = true;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAgePickerDialog() {
    final ageRanges = ["0-12", "13-17", "18-22", "23-29", "30-39", "40+"];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Select Age Range",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF046EB8),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemCount: ageRanges.length,
                itemBuilder: (context, index) {
                  final age = ageRanges[index];
                  final isSelected = selectedAge == age;

                  return _SelectionGridItem(
                    label: age,
                    isSelected: isSelected,
                    onTap: () {
                      _playClickSound();
                      setState(() {
                        selectedAge = age;
                        ageError = false;
                        _hasFormChanged = true;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSexPickerDialog() {
    final sexOptions = ["Male", "Female", "Prefer Not to Say"];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Select Sex",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF046EB8),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                children: sexOptions.map((sex) {
                  final isSelected = selectedSex == sex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SelectionGridItem(
                      label: sex,
                      isSelected: isSelected,
                      onTap: () {
                        _playClickSound();
                        setState(() {
                          selectedSex = sex;
                          sexError = false;
                          _hasFormChanged = true;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryPickerDialog() {
    final categories = [
      "Student",
      "Government Employee",
      "Private Employee",
      "Self-Employed",
      "Not Employed",
      "Others"
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Select Category",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF046EB8),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                children: categories.map((category) {
                  final isSelected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SelectionGridItem(
                      label: category,
                      isSelected: isSelected,
                      onTap: () {
                        _playClickSound();
                        setState(() {
                          selectedCategory = category;
                          categoryError = false;
                          _hasFormChanged = true;
                          if (category != "Student") {
                            selectedStudentCategory = null;
                            studentCategoryError = false;
                          }
                        });
                        Navigator.pop(context);
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStudentCategoryPickerDialog() {
    final studentCategories = [
      "Grade 1-6 (Elementary)",
      "Grade 7-10 (Junior High)",
      "Grade 11-12 (Senior High)",
      "College",
      "Graduate School"
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Select Student Category",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF046EB8),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                children: studentCategories.map((category) {
                  final isSelected = selectedStudentCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SelectionGridItem(
                      label: category,
                      isSelected: isSelected,
                      onTap: () {
                        _playClickSound();
                        setState(() {
                          selectedStudentCategory = category;
                          studentCategoryError = false;
                          _hasFormChanged = true;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRegionPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Select Region",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF046EB8),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 400,
                child: ListView.builder(
                  itemCount: region.length,
                  itemBuilder: (context, index) {
                    final reg = region[index];
                    final isSelected = selectedRegionId == reg['id'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SelectionGridItem(
                        label: reg['name']!,
                        isSelected: isSelected,
                        onTap: () {
                          _playClickSound();
                          Navigator.pop(context);
                          setState(() {
                            selectedRegionId = reg['id'];
                            selectedRegionName = reg['name'];
                            selectedProvinceId = null;
                            selectedProvinceName = null;
                            selectedCityId = null;
                            selectedCityName = null;
                            province = [];
                            city = [];
                            regionError = false;
                            _hasFormChanged = true;
                          });
                          // Fetch provinces immediately after dialog closes
                          fetchProvinces(reg['id']!);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProvincePickerDialog() {
    if (province.isEmpty) {
      _showError('Please select a region first');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Select Province",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF046EB8),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 400,
                child: ListView.builder(
                  itemCount: province.length,
                  itemBuilder: (context, index) {
                    final prov = province[index];
                    final isSelected = selectedProvinceId == prov['id'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SelectionGridItem(
                        label: prov['name']!,
                        isSelected: isSelected,
                        onTap: () {
                          _playClickSound();
                          Navigator.pop(context);
                          setState(() {
                            selectedProvinceId = prov['id'];
                            selectedProvinceName = prov['name'];
                            selectedCityId = null;
                            selectedCityName = null;
                            city = [];
                            provinceError = false;
                            _hasFormChanged = true;
                          });
                          // Fetch cities immediately after dialog closes
                          fetchCities(prov['id']!);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCityPickerDialog() {
    if (city.isEmpty) {
      _showError('Please select a province first');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Select City",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF046EB8),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 400,
                child: ListView.builder(
                  itemCount: city.length,
                  itemBuilder: (context, index) {
                    final cty = city[index];
                    final isSelected = selectedCityId == cty['id'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SelectionGridItem(
                        label: cty['name']!,
                        isSelected: isSelected,
                        onTap: () {
                          _playClickSound();
                          setState(() {
                            selectedCityId = cty['id'];
                            selectedCityName = cty['name'];
                            cityError = false;
                            _hasFormChanged = true;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> fetchRegions() async {
    if (!mounted) return;

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/region'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          region = data.map((r) => {
            'id': r['id'].toString(),
            'name': r['name'].toString(),
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching regions: $e');
    }
  }

  Future<void> fetchProvinces(String regionId) async {
    // ✅ SHOW SMALL LOADING - Loading provinces
    if (!mounted) return;
    LoadingHelper.showLoadingDialog(context, message: 'Loading provinces...', width: 300, height: 200);

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/province/$regionId'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          province = data.map((p) => {
            'id': p['id'].toString(),
            'name': p['name'].toString(),
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching provinces: $e');
    } finally {
      // ✅ HIDE LOADING after provinces are loaded
      if (mounted) LoadingHelper.hideLoading(context);
    }
  }

  Future<void> fetchCities(String provinceId) async {
    // ✅ SHOW SMALL LOADING - Loading cities
    if (!mounted) return;
    LoadingHelper.showLoadingDialog(context, message: 'Loading cities...', width: 300, height: 200);

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/city/$provinceId'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          city = data.map((c) => {
            'id': c['id'].toString(),
            'name': c['name'].toString(),
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching cities: $e');
    } finally {
      // ✅ HIDE LOADING after cities are loaded
      if (mounted) LoadingHelper.hideLoading(context);
    }
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        children: [
          // Row with circles and line
          Row(
            children: [
              _buildStepCircle(0),
              Expanded(
                child: Container(
                  height: 2,
                  color: step >= 1 ? const Color(0xFF046EB8) : Colors.grey.shade400,
                ),
              ),
              _buildStepCircle(1),
            ],
          ),
          const SizedBox(height: 8),
          // Row with labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  "Privacy Notice",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              const Expanded(
                child: Text(
                  "Personal Information",
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int stepIndex) {
    final bool isCompleted = step > stepIndex;
    final bool isActive = step == stepIndex || (stepIndex == 1 && step >= 1);
    final Color circleColor = (isActive || isCompleted) ? const Color(0xFF046EB8) : Colors.grey.shade400;
    return CircleAvatar(radius: 8, backgroundColor: circleColor);
  }

  List<String> _getAvatarList() {
    return const [
      "Adventurer", "Astronaut", "Boy", "Brainy", "Cool-Monkey",
      "Cute-Elephant", "Doctor-Boy", "Doctor-Girl", "Engineer-Boy",
      "Engineer-Girl", "Girl", "Hacker", "Leonel", "Scientist-Boy",
      "Scientist-Girl", "Sly-Fox", "Sneaky-Snake", "Teacher-Boy",
      "Teacher-Girl", "Twirky", "Whiz-Achiever", "Whiz-Busy",
      "Whiz-Happy", "Whiz-Ready", "Wise-Turtle",
    ];
  }

  Future<void> registerUser() async {
    if (!_hasFormChanged) {
      _showError('No changes have been made');
      return;
    }

    _playClickSound();
    await _buttonScaleController.forward();
    await _buttonScaleController.reverse();

    _clearErrors();
    bool hasError = false;

    // Validation
    if (usernameController.text.trim().isEmpty) {
      setState(() => usernameError = true);
      hasError = true;
    }
    if (passwordController.text.isEmpty) {
      setState(() => passwordError = true);
      hasError = true;
    }
    if (confirmPasswordController.text.isEmpty) {
      setState(() => confirmPasswordError = true);
      hasError = true;
    }
    if (selectedAvatar == null) {
      setState(() => avatarError = true);
      hasError = true;
    }
    if (selectedAge == null) {
      setState(() => ageError = true);
      hasError = true;
    }
    if (selectedSex == null) {
      setState(() => sexError = true);
      hasError = true;
    }
    if (schoolController.text.trim().isEmpty) {
      setState(() => schoolError = true);
      hasError = true;
    }
    if (selectedCategory == null) {
      setState(() => categoryError = true);
      hasError = true;
    }
    if (selectedCategory == "Student" && selectedStudentCategory == null) {
      setState(() => studentCategoryError = true);
      hasError = true;
    }
    if (selectedRegionId == null) {
      setState(() => regionError = true);
      hasError = true;
    }
    if (selectedProvinceId == null) {
      setState(() => provinceError = true);
      hasError = true;
    }
    if (selectedCityId == null) {
      setState(() => cityError = true);
      hasError = true;
    }

    if (hasError) {
      _showError('Please fill in all required fields');
      return;
    }

    String? usernameErrorMsg = _validateUsername(usernameController.text);
    if (usernameErrorMsg != null) {
      setState(() => usernameError = true);
      _showError(usernameErrorMsg);
      return;
    }

    String? passwordErrorMsg = _validatePassword(passwordController.text);
    if (passwordErrorMsg != null) {
      setState(() => passwordError = true);
      _showError(passwordErrorMsg);
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        passwordError = true;
        confirmPasswordError = true;
      });
      _showError('Passwords do not match');
      return;
    }

    String? schoolErrorMsg = _validateSchool(schoolController.text);
    if (schoolErrorMsg != null) {
      setState(() => schoolError = true);
      _showError(schoolErrorMsg);
      return;
    }

    final payload = {
      "username": usernameController.text.trim(),
      "password": passwordController.text,
      "school": schoolController.text.trim(),
      "age": selectedAge ?? "",
      "avatar": selectedAvatar ?? "",
      "category": selectedCategory ?? "",
      "student_category": selectedCategory == "Student" ? selectedStudentCategory : null,
      "sex": selectedSex ?? "",
      "region": selectedRegionId,
      "province": selectedProvinceId,
      "city": selectedCityId,
    };

    // ✅ SHOW LOADING - All validations passed, creating account
    if (!mounted) return;
    LoadingHelper.showLoadingDialog(context, message: 'Creating account...', width: 300, height: 200);

    final url = Uri.parse('$baseUrl/api/user/register');
    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      // ✅ HIDE LOADING before showing success dialog
      if (mounted) LoadingHelper.hideLoading(context);

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        if (!mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
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
                    "Your account has been created successfully. Please log in to continue.",
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
                        _playClickSound();
                        Navigator.pop(context); // Close dialog

                        // Navigate back to login screen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDD000),
                        foregroundColor: const Color(0xFF816A03),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  )
                ],
              ),
            ),
          ),
        );
      } else {
        // ✅ HIDE LOADING before showing error
        if (mounted) LoadingHelper.hideLoading(context);

        String message = 'Registration failed';
        try {
          final jsonBody = jsonDecode(resp.body);
          if (jsonBody is Map) {
            if (jsonBody['errors'] != null) {
              final errors = jsonBody['errors'] as Map<String, dynamic>;
              final firstError = errors.values.first;
              message = firstError is List ? firstError.first : firstError.toString();
            } else if (jsonBody['message'] != null) {
              message = jsonBody['message'];
            }
          }
        } catch (_) {
          message = resp.body;
        }
        if (!mounted) return;
        _showError(message);
      }
    } catch (e) {
      // ✅ HIDE LOADING on network error
      if (mounted) LoadingHelper.hideLoading(context);

      if (!mounted) return;
      _showError('Network error. Please check your connection.');
    }
  }

  Widget _buildTextField(
      IconData icon,
      String hint, {
        TextEditingController? controller,
        bool hasError = false,
        void Function(String)? onChanged,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13, fontFamily: "Poppins"),
        decoration: _inputDecoration(hint, icon: icon, hasError: hasError),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildPasswordField(
      IconData icon,
      String hint,
      bool hide,
      void Function(bool) toggle,
      TextEditingController controller,
      bool hasError, {
        void Function(String)? onChanged,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: hide,
        style: const TextStyle(fontSize: 13, fontFamily: "Poppins"),
        decoration: _inputDecoration(hint, icon: icon, hasError: hasError).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              hide ? Icons.visibility : Icons.visibility_off,
              size: 18,
              color: hasError ? Colors.red : null,
            ),
            onPressed: () => toggle(!hide),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildClickableField(
      String label,
      String? value,
      VoidCallback onTap, {
        bool hasError = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasError ? Colors.red : Colors.grey,
                    width: hasError ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      value ?? label,
                      style: TextStyle(
                        fontSize: 13,
                        color: value != null ? Colors.black : Colors.grey,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
              ),
            ),
          ),
          if (hasError)
            const Padding(
              padding: EdgeInsets.only(left: 12, top: 4),
              child: Text('Required', style: TextStyle(color: Colors.red, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon, bool hasError = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13,
        fontFamily: "Poppins",
        color: hasError ? Colors.red.shade300 : null,
      ),
      prefixIcon: icon != null ? Icon(icon, size: 18, color: hasError ? Colors.red : null) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey, width: hasError ? 2 : 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: hasError ? Colors.red : const Color(0xFF046EB8), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  void _handleBack(BuildContext context) {
    if (step > 0) {
      setState(() => step--);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Widget _buildOutlinedButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF046EB8), width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      ),
      onPressed: () {
        _playClickSound();
        onPressed();
      },
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.normal)),
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
        const SizedBox(height: 15),
        Center(
          child: Image.asset("assets/images-logo/bird1.png", height: 120),
        ),
        const SizedBox(height: 15),
        const Center(
          child: Text(
            "Terms and Conditions",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "By accessing STARBOOKS WHIZ CHALLENGE, you agree to these terms and conditions. "
              "We collect personal information and usage data to improve our services and efficiency. "
              "We prioritize data security and do not share personal information with third parties without consent, "
              "except as required by law. Users must provide accurate information and comply with all laws while using our site. "
              "For questions, contact us at support@starbookswhizbee.com",
          style: TextStyle(fontSize: 16, height: 1.6),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }

  Widget _buildPersonalInfoContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Personal Information",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24, color: Color(0xFF046EB8)),
          ),
          const SizedBox(height: 20),
          // 30-70 split: Avatar on left, form fields on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT SIDE - Avatar (30%)
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _showAvatarPickerDialog(),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 70,
                            backgroundColor: avatarError ? Colors.red : const Color(0xFFFDD000),
                            child: CircleAvatar(
                              radius: 67,
                              backgroundColor: Colors.white,
                              backgroundImage: selectedAvatar != null ? AssetImage(selectedAvatar!) : null,
                              child: selectedAvatar == null ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: ElevatedButton(
                        onPressed: () => _showAvatarPickerDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFDD000),
                          foregroundColor: const Color(0xFF816A03),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 2,
                        ),
                        child: const Text(
                          "Change Avatar",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    if (avatarError)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('Required', style: TextStyle(color: Colors.red, fontSize: 11)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // RIGHT SIDE - Form fields (70%)
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    _buildTextField(Icons.person, "Username", controller: usernameController, hasError: usernameError, onChanged: (_) => setState(() => usernameError = false)),
                    _buildPasswordField(Icons.lock, "Password", hidePassword, (val) => setState(() => hidePassword = !hidePassword), passwordController, passwordError, onChanged: (_) => setState(() => passwordError = false)),
                    _buildPasswordField(Icons.lock, "Confirm Password", hideConfirmPassword, (val) => setState(() => hideConfirmPassword = !hideConfirmPassword), confirmPasswordController, confirmPasswordError, onChanged: (_) => setState(() => confirmPasswordError = false)),
                    const SizedBox(height: 6),
                    // Age and Sex with box selection
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => _showAgePickerDialog(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: ageError ? Colors.red : Colors.grey,
                                        width: ageError ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          selectedAge ?? "Age",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: selectedAge != null ? Colors.black : Colors.grey,
                                          ),
                                        ),
                                        const Icon(Icons.arrow_drop_down, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (ageError)
                                const Padding(
                                  padding: EdgeInsets.only(left: 12, top: 4),
                                  child: Text('Required', style: TextStyle(color: Colors.red, fontSize: 11)),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => _showSexPickerDialog(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: sexError ? Colors.red : Colors.grey,
                                        width: sexError ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          selectedSex ?? "Sex",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: selectedSex != null ? Colors.black : Colors.grey,
                                          ),
                                        ),
                                        const Icon(Icons.arrow_drop_down, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (sexError)
                                const Padding(
                                  padding: EdgeInsets.only(left: 12, top: 4),
                                  child: Text('Required', style: TextStyle(color: Colors.red, fontSize: 11)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolLocationContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Personal Information",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: Color(0xFF046EB8)),
          ),
          const SizedBox(height: 20),
          // School - full width
          _buildTextField(Icons.school, "School", controller: schoolController, hasError: schoolError, onChanged: (_) => setState(() => schoolError = false)),
          // Category - full width
          _buildClickableField(
            "Category",
            selectedCategory,
                () => _showCategoryPickerDialog(),
            hasError: categoryError,
          ),
          if (selectedCategory == "Student")
            _buildClickableField(
              "Student Category",
              selectedStudentCategory,
                  () => _showStudentCategoryPickerDialog(),
              hasError: studentCategoryError,
            ),
          const SizedBox(height: 6),
          // Three columns for Region, Province, City
          Row(
            children: [
              Expanded(
                child: _buildClickableField(
                  "Region",
                  selectedRegionName,
                      () => _showRegionPickerDialog(),
                  hasError: regionError,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildClickableField(
                  "Province",
                  selectedProvinceName,
                      () => _showProvincePickerDialog(),
                  hasError: provinceError,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildClickableField(
                  "City",
                  selectedCityName,
                      () => _showCityPickerDialog(),
                  hasError: cityError,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: Listenable.merge([_buttonScaleController, _fadeController]),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF94D2FD),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset("assets/images-logo/starbooksnewlogo.png", height: 50),
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
              Image.asset(
                "assets/images-icons/background1.png",
                width: screenWidth,
                height: screenHeight,
                fit: BoxFit.cover,
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900, minWidth: 400),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: step == 0 ? 450 : 480,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildStepper(),
                        const SizedBox(height: 20),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 600),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(opacity: animation, child: child),
                            child: SingleChildScrollView(
                              key: ValueKey(step),
                              child: step == 0 ? _buildPrivacyStepContent() : (step == 1 ? _buildPersonalInfoContent() : _buildSchoolLocationContent()),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildOutlinedButton("Back", () => _handleBack(context)),
                            if (step == 0)
                              _buildOutlinedButton("Proceed", () {
                                _fadeController.reset();
                                setState(() => step = 1);
                                _fadeController.forward();
                              })
                            else if (step == 1)
                              _buildOutlinedButton("Next", () {
                                if (_validateStep1()) {
                                  _fadeController.reset();
                                  setState(() => step = 2);
                                  _fadeController.forward();
                                }
                              })
                            else
                              Transform.scale(
                                scale: _buttonScale.value,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFDD000),
                                    foregroundColor: const Color(0xFFAC8337),
                                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                                  ),
                                  onPressed: (!_hasFormChanged) ? null : registerUser,
                                  child: Text(
                                    _hasFormChanged ? "REGISTER" : "NO CHANGES",
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                          ],
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

class _AvatarGridItem extends StatefulWidget {
  final String avatarName;
  final String avatarPath;
  final bool isSelected;
  final VoidCallback onTap;

  const _AvatarGridItem({
    required this.avatarName,
    required this.avatarPath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AvatarGridItem> createState() => _AvatarGridItemState();
}

class _AvatarGridItemState extends State<_AvatarGridItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFFFDD000)  // Same yellow as Change Avatar button
                : _isHovered
                ? const Color(0xFFFDD000).withValues(alpha: 0.5)  // 50% transparent yellow for hover
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected ? const Color(0xFFFDD000) : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:_isHovered ? 0.1 : 0.05),
                blurRadius: _isHovered ? 6 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                widget.avatarPath,
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 4),
              Text(
                widget.avatarName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionGridItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionGridItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SelectionGridItem> createState() => _SelectionGridItemState();
}

class _SelectionGridItemState extends State<_SelectionGridItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFFFDD000)  // Same yellow as Change Avatar button
                : _isHovered
                ? const Color(0xFFFDD000).withValues(alpha: 0.5)  // 50% transparent yellow for hover
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected ? const Color(0xFFFDD000) : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:_isHovered ? 0.1 : 0.05),
                blurRadius: _isHovered ? 6 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
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