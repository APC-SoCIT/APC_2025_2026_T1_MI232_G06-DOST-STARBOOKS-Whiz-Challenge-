import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChangePasswordDialog extends StatefulWidget {
  final String userId; // required
  const ChangePasswordDialog({super.key, required this.userId});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool showOld = false;
  bool showNew = false;
  bool showConfirm = false;
  bool saving = false;

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
    if (newPasswordController.text.isEmpty ||
        oldPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match.")),
      );
      return;
    }

    setState(() => saving = true);

    // Store safe references before async call
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final url = Uri.parse("http://127.0.0.1:8000/api/change-password"); // adjust if needed

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "old_password": oldPasswordController.text,
          "new_password": newPasswordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        navigator.pop(); // close the change password dialog
        await _showSuccessDialog(); // show success popup
      } else {
        final message = jsonDecode(response.body)['message'] ?? "Error occurred.";
        messenger.showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Success image (you can replace with your asset image)
                Image.asset(
                  'assets/images-logo/bird1.png',
                  width: 160,
                  height: 160,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Password Changed!",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF046EB8),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Your password has been updated successfully.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDD000),
                    foregroundColor: const Color(0xFF816A03),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
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
              decoration: _inputDecoration("Old Password", icon: Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(showOld ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => showOld = !showOld),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // New password
            TextField(
              controller: newPasswordController,
              obscureText: !showNew,
              decoration: _inputDecoration("New Password", icon: Icons.lock).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(showNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => showNew = !showNew),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Confirm password
            TextField(
              controller: confirmPasswordController,
              obscureText: !showConfirm,
              decoration: _inputDecoration("Confirm Password", icon: Icons.lock).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(showConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => showConfirm = !showConfirm),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                    child: CircularProgressIndicator(strokeWidth: 2),
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
