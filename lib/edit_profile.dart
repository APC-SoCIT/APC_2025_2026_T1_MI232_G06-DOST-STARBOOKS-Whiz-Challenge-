import 'package:flutter/material.dart';
import 'homepage.dart';
import 'change_password.dart';

class EditProfileDialog extends StatefulWidget {
  final UserProfile profile;
  const EditProfileDialog({super.key, required this.profile});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late String username;
  late String school;
  late String age;
  late String category;
  late String sex;
  late String region;
  late String province;
  late String city;
  late String avatar;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController schoolController = TextEditingController();

  final List<String> ageOptions = [
    "0-12",
    "13-17",
    "18-22",
    "23-29",
    "30-39",
    "40+",
  ];

  final List<String> categoryOptions = [
    "Student",
    "Government Employee",
    "Private Employee",
    "Self-Employed",
    "Not Employed",
    "Others",
  ];

  final List<String> sexOptions = ["Male", "Female", "Prefer not to say"];

  final List<String> regionOptions = [
    "BARMM",
    "CAR",
    "NCR",
    "Region I",
    "Region II",
    "Region III",
    "Region IV-A",
    "Region IV-B",
    "Region V",
    "Region VI",
    "Region VII",
    "Region VIII",
    "Region IX",
    "Region X",
    "Region XI",
    "Region XII",
    "Region XIII (Caraga)",
    "NIR",
  ];

  final List<String> avatarOptions = [
    "Sly-Fox",
    "Astronaut",
    "Whiz-Busy",
    "Twirky",
  ];

  final Map<String, String> avatarMap = {
    "Sly-Fox": "assets/images-avatars/Sly-Fox.png",
    "Astronaut": "assets/images-avatars/Astronaut.png",
    "Whiz-Busy": "assets/images-avatars/Whiz-Busy.png",
    "Twirky": "assets/images-avatars/Twirky.png",
  };

  final Map<String, List<String>> provinceOptions = {
    "NCR": ["Metro Manila"],
    "Region IV-A": ["Cavite", "Laguna", "Batangas", "Rizal", "Quezon"],
    "Region VI": [
      "Aklan",
      "Antique",
      "Capiz",
      "Guimaras",
      "Iloilo",
      "Negros Occidental",
    ],
  };

  final Map<String, List<String>> cityOptions = {
    "Metro Manila": ["Quezon City", "Makati City", "Manila", "Pasig"],
    "Cavite": ["Dasmariñas", "Bacoor", "Imus"],
    "Laguna": ["Calamba", "Santa Rosa", "Biñan"],
    "Iloilo": ["Iloilo City", "Oton", "Pavia"],
  };

  @override
  void initState() {
    super.initState();
    username = widget.profile.username;
    school = widget.profile.school;
    age = widget.profile.age;
    category = widget.profile.category;
    sex = widget.profile.sex;
    region = widget.profile.region;
    province = widget.profile.province;
    city = widget.profile.city;
    avatar = widget.profile.avatar;

    usernameController.text = username;
    schoolController.text = school;
  }

  void saveProfile() {
    Navigator.pop(
      context,
      UserProfile(
        username: usernameController.text,
        school: schoolController.text,
        age: age,
        category: category,
        sex: sex,
        region: region,
        province: province,
        city: city,
        avatar: avatar,
      ),
    );
  }

  InputDecoration roundedFieldDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFF046EB8), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarPath = avatarMap[avatar];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.57,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.edit, color: Colors.black),
                      SizedBox(width: 8),
                      Text(
                        "Edit Profile",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const ChangePasswordDialog(),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF046EB8),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.key, color: Color(0xFF046EB8)),
                    label: const Text(
                      "Change Password",
                      style: TextStyle(color: Color(0xFF046EB8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Avatar + username
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFD13B),
                        width: 6,
                      ),
                    ),
                    child: ClipOval(
                      child: avatarPath == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Color(0xFF442700),
                            )
                          : Image.asset(avatarPath, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: usernameController,
                          decoration: roundedFieldDecoration(
                            "Username",
                            icon: Icons.person,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: schoolController,
                                decoration: roundedFieldDecoration("School"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: age.isNotEmpty ? age : null,
                                items: ageOptions
                                    .map(
                                      (val) => DropdownMenuItem(
                                        value: val,
                                        child: Text(val),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) => setState(() => age = val!),
                                decoration: roundedFieldDecoration("Age"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Dropdowns row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: avatar.isNotEmpty ? avatar : null,
                      items: avatarOptions
                          .map(
                            (val) =>
                                DropdownMenuItem(value: val, child: Text(val)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => avatar = val!),
                      decoration: roundedFieldDecoration("Avatar"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: category.isNotEmpty ? category : null,
                      items: categoryOptions
                          .map(
                            (val) =>
                                DropdownMenuItem(value: val, child: Text(val)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => category = val!),
                      decoration: roundedFieldDecoration("Category"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: sex.isNotEmpty ? sex : null,
                      items: sexOptions
                          .map(
                            (val) =>
                                DropdownMenuItem(value: val, child: Text(val)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => sex = val!),
                      decoration: roundedFieldDecoration("Sex"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: region.isNotEmpty ? region : null,
                      items: regionOptions
                          .map(
                            (val) =>
                                DropdownMenuItem(value: val, child: Text(val)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() {
                        region = val!;
                        province = "";
                        city = "";
                      }),
                      decoration: roundedFieldDecoration("Region"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: province.isEmpty ? null : province,
                      items: provinceOptions[region]
                          ?.map(
                            (val) =>
                                DropdownMenuItem(value: val, child: Text(val)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() {
                        province = val!;
                        city = "";
                      }),
                      decoration: roundedFieldDecoration("Province"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: city.isEmpty ? null : city,
                      items: cityOptions[province]
                          ?.map(
                            (val) =>
                                DropdownMenuItem(value: val, child: Text(val)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => city = val!),
                      decoration: roundedFieldDecoration("City"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD13B),
                      foregroundColor: const Color(0xFF915701),
                    ),
                    onPressed: saveProfile,
                    child: const Text(
                      "SAVE CHANGES",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
