import 'package:flutter/material.dart';
import 'package:flutter_projects/change_password.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'homepage.dart'; // contains UserProfile class

class EditProfileDialog extends StatefulWidget {
  final UserProfile profile;

  const EditProfileDialog({super.key, required this.profile});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final String baseUrl = "http://127.0.0.1:8000";
  final _formKey = GlobalKey<FormState>();

  late TextEditingController usernameController;
  late TextEditingController schoolController;

  String? selectedAvatar;
  String? selectedAge;
  String? selectedCategory;
  String? selectedSex;
  String? selectedRegionId;
  String? selectedProvinceId;
  String? selectedCityId;

  List<Map<String, String>> regions = [];
  List<Map<String, String>> provinces = [];
  List<Map<String, String>> cities = [];

  bool saving = false;
  bool loadingInitialData = true;

  final List<String> avatarPaths = [
    "assets/images-avatars/Adventurer.png",
    "assets/images-avatars/Astronaut.png",
    "assets/images-avatars/Boy.png",
    "assets/images-avatars/Brainy.png",
    "assets/images-avatars/Cool-Monkey.png",
    "assets/images-avatars/Cute-Elephant.png",
    "assets/images-avatars/Doctor-Boy.png",
    "assets/images-avatars/Doctor-Girl.png",
    "assets/images-avatars/Engineer-Boy.png",
    "assets/images-avatars/Engineer-Girl.png",
    "assets/images-avatars/Girl.png",
    "assets/images-avatars/Hacker.png",
    "assets/images-avatars/Leonel.png",
    "assets/images-avatars/Scientist-Boy.png",
    "assets/images-avatars/Scientist-Girl.png",
    "assets/images-avatars/Sly-Fox.png",
    "assets/images-avatars/Sneaky-Snake.png",
    "assets/images-avatars/Teacher-Boy.png",
    "assets/images-avatars/Teacher-Girl.png",
    "assets/images-avatars/Twirky.png",
    "assets/images-avatars/Whiz-Achiever.png",
    "assets/images-avatars/Whiz-Busy.png",
    "assets/images-avatars/Whiz-Happy.png",
    "assets/images-avatars/Whiz-Ready.png",
    "assets/images-avatars/Wise-Turtle.png",
  ];

  late final List<String> avatarNames = avatarPaths
      .map(
        (path) =>
            path.split('/').last.replaceAll('.png', '').replaceAll('-', ' '),
      )
      .toList();

  @override
  void initState() {
    super.initState();

    usernameController = TextEditingController(text: widget.profile.username);
    schoolController = TextEditingController(text: widget.profile.school);

    selectedAvatar = widget.profile.avatar;
    selectedAge = widget.profile.age;
    selectedCategory = widget.profile.category;
    selectedSex = widget.profile.sex;

    _initializeLocationData();
  }

  /// Initialize location dropdowns by fetching user's current location IDs
  Future<void> _initializeLocationData() async {
    setState(() => loadingInitialData = true);

    try {
      // Fetch all regions first
      await fetchRegions();

      // Get user's current location IDs from backend
      final userResp = await http.get(
        Uri.parse('$baseUrl/api/user/profile/${widget.profile.id}'),
      );

      if (userResp.statusCode == 200) {
        final userData = jsonDecode(userResp.body);
        if (userData['success'] == true) {
          final user = userData['user'];

          // Set the IDs from database
          selectedRegionId = user['region']?.toString();
          selectedProvinceId = user['province']?.toString();
          selectedCityId = user['city']?.toString();

          // Fetch provinces and cities based on stored IDs
          if (selectedRegionId != null && selectedRegionId!.isNotEmpty) {
            await fetchProvinces(selectedRegionId!);
          }

          if (selectedProvinceId != null && selectedProvinceId!.isNotEmpty) {
            await fetchCities(selectedProvinceId!);
          }
        }
      }
    } catch (e) {
      debugPrint('Error initializing location data: $e');
    } finally {
      setState(() => loadingInitialData = false);
    }
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, fontFamily: "Poppins"),
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
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Future<void> fetchRegions() async {
    try {
      final resp = await http.get(Uri.parse('$baseUrl/api/region'));
      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        regions = data
            .map<Map<String, String>>(
              (e) => {
                'id': e['id'].toString(),
                'name': (e['region_name'] ?? e['name']).toString(),
              },
            )
            .toList();
        setState(() {});
      }
    } catch (e) {
      debugPrint('fetchRegions error: $e');
    }
  }

  Future<void> fetchProvinces(String regionId) async {
    try {
      final resp = await http.get(Uri.parse('$baseUrl/api/province/$regionId'));
      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        provinces = data
            .map<Map<String, String>>(
              (e) => {
                'id': e['id'].toString(),
                'name': (e['province_name'] ?? e['name']).toString(),
              },
            )
            .toList();
        setState(() {});
      }
    } catch (e) {
      debugPrint('fetchProvinces error: $e');
    }
  }

  Future<void> fetchCities(String provinceId) async {
    try {
      final resp = await http.get(Uri.parse('$baseUrl/api/city/$provinceId'));
      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        cities = data
            .map<Map<String, String>>(
              (e) => {
                'id': e['id'].toString(),
                'name': (e['city_name'] ?? e['name']).toString(),
              },
            )
            .toList();
        setState(() {});
      }
    } catch (e) {
      debugPrint('fetchCities error: $e');
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate location selections
    if (selectedRegionId == null ||
        selectedProvinceId == null ||
        selectedCityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Region, Province, and City'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => saving = true);

    try {
      // Prepare payload with integer IDs (as backend expects)
      final payload = {
        'username': usernameController.text.trim(),
        'school': schoolController.text.trim(),
        'age': selectedAge,
        'category': selectedCategory,
        'sex': selectedSex,
        'avatar': selectedAvatar,
        'region': int.parse(selectedRegionId!),
        'province': int.parse(selectedProvinceId!),
        'city': int.parse(selectedCityId!),
      };

      final resp = await http.put(
        Uri.parse('$baseUrl/api/user/update/${widget.profile.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (resp.statusCode == 200) {
        final responseData = jsonDecode(resp.body);

        // Get the readable names for the updated profile
        final regionName =
            regions.firstWhere(
              (r) => r['id'] == selectedRegionId,
              orElse: () => {'name': ''},
            )['name'] ??
            '';

        final provinceName =
            provinces.firstWhere(
              (p) => p['id'] == selectedProvinceId,
              orElse: () => {'name': ''},
            )['name'] ??
            '';

        final cityName =
            cities.firstWhere(
              (c) => c['id'] == selectedCityId,
              orElse: () => {'name': ''},
            )['name'] ??
            '';

        // Create updated profile with readable names
        final updatedProfile = widget.profile.copyWith(
          username: usernameController.text.trim(),
          school: schoolController.text.trim(),
          age: selectedAge,
          category: selectedCategory,
          sex: selectedSex,
          avatar: selectedAvatar,
          region: regionName,
          province: provinceName,
          city: cityName,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, updatedProfile);
        }
      } else {
        if (mounted) {
          final errorMsg = jsonDecode(resp.body)['message'] ?? resp.body;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: $errorMsg'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loadingInitialData) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 890,
          height: 370,
          padding: const EdgeInsets.all(30),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF046EB8)),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 1010,
        height: 380,
        padding: const EdgeInsets.all(30),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header Row: Edit + Change Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.edit, color: Colors.black, size: 26),
                      SizedBox(width: 8),
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            ChangePasswordDialog(userId: widget.profile.id),
                      );
                    },
                    icon: const Icon(Icons.vpn_key, color: Color(0xFF046EB8)),
                    label: const Text(
                      'Change Password',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Color(0xFF046EB8),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF046EB8),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Avatar + Name/School + Dropdowns
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 75,
                      backgroundColor: const Color(0xFFFDD000),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white,
                        backgroundImage: selectedAvatar != null
                            ? AssetImage(selectedAvatar!)
                            : null,
                        child: selectedAvatar == null
                            ? const Icon(
                                Icons.person,
                                size: 25,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: usernameController,
                            decoration: _inputDecoration('Username'),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? 'Username required'
                                : null,
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: schoolController,
                                  decoration: _inputDecoration('School'),
                                  validator: (val) =>
                                      val == null || val.trim().isEmpty
                                      ? 'School required'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: selectedAge,
                                  decoration: _inputDecoration('Age'),
                                  items:
                                      const [
                                            "0-12",
                                            "13-17",
                                            "18-22",
                                            "23-29",
                                            "30-39",
                                            "40+",
                                          ]
                                          .map(
                                            (age) => DropdownMenuItem(
                                              value: age,
                                              child: Text(age),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (val) =>
                                      setState(() => selectedAge = val),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: selectedAvatar,
                                  decoration: _inputDecoration('Avatar'),
                                  items: List.generate(
                                    avatarPaths.length,
                                    (index) => DropdownMenuItem(
                                      value: avatarPaths[index],
                                      child: Text(avatarNames[index]),
                                    ),
                                  ),
                                  onChanged: (val) =>
                                      setState(() => selectedAvatar = val),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: selectedCategory,
                                  decoration: _inputDecoration('Category'),
                                  items:
                                      const [
                                            "Student",
                                            "Government Employee",
                                            "Private Employee",
                                            "Self-Employed",
                                            "Not Employed",
                                            "Others",
                                          ]
                                          .map(
                                            (cat) => DropdownMenuItem(
                                              value: cat,
                                              child: Text(cat),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (val) =>
                                      setState(() => selectedCategory = val),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: selectedSex,
                                  decoration: _inputDecoration('Sex'),
                                  items: const ["Male", "Female"]
                                      .map(
                                        (sex) => DropdownMenuItem(
                                          value: sex,
                                          child: Text(sex),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => selectedSex = val),
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

              const SizedBox(height: 15),

              // Region / Province / City
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedRegionId,
                      decoration: _inputDecoration('Region'),
                      items: regions
                          .map(
                            (r) => DropdownMenuItem(
                              value: r['id'],
                              child: Text(r['name'] ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          selectedRegionId = val;
                          selectedProvinceId = null;
                          selectedCityId = null;
                          provinces = [];
                          cities = [];
                        });
                        fetchProvinces(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedProvinceId,
                      decoration: _inputDecoration('Province'),
                      items: provinces
                          .map(
                            (p) => DropdownMenuItem(
                              value: p['id'],
                              child: Text(p['name'] ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          selectedProvinceId = val;
                          selectedCityId = null;
                          cities = [];
                        });
                        fetchCities(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedCityId,
                      decoration: _inputDecoration('City'),
                      items: cities
                          .map(
                            (c) => DropdownMenuItem(
                              value: c['id'],
                              child: Text(c['name'] ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => selectedCityId = val),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Cancel / Save buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF046EB8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
                      side: const BorderSide(
                        color: Color(0xFF046EB8),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD000),
                      foregroundColor: const Color(0xFF816A03),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: saving ? null : saveProfile,
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF816A03),
                            ),
                          )
                        : const Text('SAVE CHANGES'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
