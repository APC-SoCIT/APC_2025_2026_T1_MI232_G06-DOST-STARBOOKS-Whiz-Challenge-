import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'admin_login.dart';
import 'api_service.dart';
import 'loading_page.dart';

/// Entry point for the admin side. Drop this in wherever you currently
/// instantiate `AdminLoginPage()` as the first admin screen (e.g. the
/// route the "ADMIN" link/button pushes to).
///
/// On load it checks for a saved admin token:
///   Token exists + profile fetch succeeds → AdminDashboard (stays logged in)
///   No token, or token invalid/expired    → AdminLoginPage
class AdminAuthGate extends StatefulWidget {
  const AdminAuthGate({super.key});

  @override
  State<AdminAuthGate> createState() => _AdminAuthGateState();
}

class _AdminAuthGateState extends State<AdminAuthGate> {
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final token = await _api.getToken();

    if (token == null || token.isEmpty) {
      _goToLogin();
      return;
    }

    // Token exists — confirm it's still valid and pull fresh admin info.
    final result = await _api.getProfile();

    if (!mounted) return;

    if (result['success'] == true) {
      // Handle either {'success': true, 'admin': {...}} or the admin
      // fields sitting flat at the top level alongside 'success'.
      final Map<String, dynamic> profile =
          (result['admin'] as Map<String, dynamic>?) ??
          (Map<String, dynamic>.from(result)..remove('success')..remove('message'));

      final adminData = <String, dynamic>{
        ...profile,
        'token': token,
      };
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AdminDashboard(adminData: adminData)),
      );
    } else {
      // Token expired/invalid server-side — clear it and send to login.
      await _api.clearToken();
      _goToLogin();
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminLoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Same loading screen used everywhere else in the admin flow
    // (e.g. admin_login.dart's LoadingHelper.showLoadingPage), shown
    // briefly while the token/profile check runs.
    return const LoadingPage(message: 'Loading admin session...');
  }
}