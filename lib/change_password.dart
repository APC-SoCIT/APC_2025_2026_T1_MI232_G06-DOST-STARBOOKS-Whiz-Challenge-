import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChangePasswordDialog extends StatefulWidget {
  final String userId;

  const ChangePasswordDialog({super.key, required this.userId});

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
  bool saving = false;

  final String baseUrl = "http://127.0.0.1:8000";

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
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

  Future<void> updatePassword() async {
    final oldPassword = oldPasswordController.text.trim();
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    // Validation
    if (oldPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your current password."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a new password."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("New password must be at least 6 characters."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/user/change-password/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Password updated successfully!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? "Failed to update password."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? "Error updating password. Please try again.",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: const [
                Icon(Icons.vpn_key, color: Colors.black, size: 26),
                SizedBox(width: 8),
                Text(
                  "Change Password",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.black,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Old password
            TextField(
              controller: oldPasswordController,
              obscureText: !showOld,
              decoration:
                  _inputDecoration(
                    "Old Password",
                    icon: Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        showOld ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => showOld = !showOld),
                    ),
                  ),
            ),
            const SizedBox(height: 15),

            // New password
            TextField(
              controller: newPasswordController,
              obscureText: !showNew,
              decoration: _inputDecoration("New Password", icon: Icons.lock)
                  .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        showNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => showNew = !showNew),
                    ),
                  ),
            ),
            const SizedBox(height: 15),

            // Confirm password
            TextField(
              controller: confirmPasswordController,
              obscureText: !showConfirm,
              decoration: _inputDecoration("Confirm Password", icon: Icons.lock)
                  .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        showConfirm ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => showConfirm = !showConfirm),
                    ),
                  ),
            ),

            const SizedBox(height: 25),

            // Buttons (Cancel / Save)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cancel
                TextButton(
                  onPressed: () => Navigator.pop(context),
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
                    side: const BorderSide(color: Color(0xFF046EB8), width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),

                // Save (Change Password)
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
                  onPressed: saving ? null : updatePassword,
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF816A03),
                            ),
                          ),
                        )
                      : const Text('CHANGE PASSWORD'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
