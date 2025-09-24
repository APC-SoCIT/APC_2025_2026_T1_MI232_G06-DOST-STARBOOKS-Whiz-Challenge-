import 'package:flutter/material.dart';
import 'change_password.dart'; // now we will create this file

// Edit Profile Popup
class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  // Mock profile data
  String username = "Player123";
  String school = "";
  String age = "18-22";
  String category = "Student";
  String sex = "Prefer not to say";
  String region = "NCR";
  String province = "";
  String city = "";
  String avatar = "Default";

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController schoolController = TextEditingController();

  // Dropdown options
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
    "Default",
    "Avatar 1",
    "Avatar 2",
    "Avatar 3",
  ];

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
    "Metro Manila": ["Quezon City", "Makati", "Manila", "Pasig"],
    "Cavite": ["Dasmariñas", "Bacoor", "Imus"],
    "Laguna": ["Calamba", "Santa Rosa", "Biñan"],
    "Iloilo": ["Iloilo City", "Oton", "Pavia"],
  };

  @override
  void initState() {
    super.initState();
    usernameController.text = username;
    schoolController.text = school;
  }

  // Mock save
  void saveProfile() {
    setState(() {
      username = usernameController.text;
      school = schoolController.text;
    });

    Navigator.pop(context); // close dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile saved (local only).")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
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
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color.fromARGB(255, 255, 209, 59),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Color.fromARGB(255, 68, 39, 0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            hintText: "Username",
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: schoolController,
                                decoration: const InputDecoration(
                                  hintText: "School",
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: age,
                                items: ageOptions
                                    .map(
                                      (val) => DropdownMenuItem(
                                        value: val,
                                        child: Text(val),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) => setState(() => age = val!),
                                decoration: const InputDecoration(
                                  hintText: "Age",
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

              const SizedBox(height: 10),

              // Other dropdowns
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: avatar,
                      items: avatarOptions
                          .map(
                            (val) =>
                                DropdownMenuItem(value: val, child: Text(val)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => avatar = val!),
                      decoration: const InputDecoration(hintText: "Avatar"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: category,
                      items: categoryOptions
                          .map(
                            (val) =>
                                DropdownMenuItem(value: val, child: Text(val)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => category = val!),
                      decoration: const InputDecoration(hintText: "Category"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: sex,
                      items: sexOptions
                          .map(
                            (val) =>
                                DropdownMenuItem(value: val, child: Text(val)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => sex = val!),
                      decoration: const InputDecoration(hintText: "Sex"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: region,
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
                      decoration: const InputDecoration(hintText: "Region"),
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
                      decoration: const InputDecoration(hintText: "Province"),
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
                      decoration: const InputDecoration(hintText: "City"),
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
                      backgroundColor: Color.fromARGB(255, 255, 209, 59),
                      foregroundColor: Color.fromARGB(255, 145, 87, 1),
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
