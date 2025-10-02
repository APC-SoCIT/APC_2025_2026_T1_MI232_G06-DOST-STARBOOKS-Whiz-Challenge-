import 'package:flutter/material.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool showOld = false;
  bool showNew = false;
  bool showConfirm = false;

  void updatePassword() {
    if (newPasswordController.text == confirmPasswordController.text &&
        newPasswordController.text.isNotEmpty) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated (local only).")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match.")));
    }
  }

  InputDecoration _roundedInputDecoration({
    required String hint,
    required IconData prefix,
    required bool obscureToggle,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefix),
      suffixIcon: IconButton(
        icon: Icon(obscureToggle ? Icons.visibility_off : Icons.visibility),
        onPressed: onToggle,
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFF046EB8), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 280,
          maxWidth: MediaQuery.of(context).size.width * 0.4, // responsive
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: const [
                  Icon(Icons.key, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    "Change Password",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Old Password
              TextField(
                controller: oldPasswordController,
                obscureText: !showOld,
                decoration: _roundedInputDecoration(
                  hint: "Old Password",
                  prefix: Icons.lock_outline,
                  obscureToggle: showOld,
                  onToggle: () => setState(() => showOld = !showOld),
                ),
              ),
              const SizedBox(height: 12),

              // New Password
              TextField(
                controller: newPasswordController,
                obscureText: !showNew,
                decoration: _roundedInputDecoration(
                  hint: "New Password",
                  prefix: Icons.lock,
                  obscureToggle: showNew,
                  onToggle: () => setState(() => showNew = !showNew),
                ),
              ),
              const SizedBox(height: 12),

              // Confirm Password
              TextField(
                controller: confirmPasswordController,
                obscureText: !showConfirm,
                decoration: _roundedInputDecoration(
                  hint: "Confirm Password",
                  prefix: Icons.lock,
                  obscureToggle: showConfirm,
                  onToggle: () => setState(() => showConfirm = !showConfirm),
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 209, 59),
                      foregroundColor: const Color.fromARGB(255, 145, 87, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onPressed: updatePassword,
                    child: const Text(
                      "CHANGE PASSWORD",
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
