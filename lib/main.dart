import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'audio_service.dart';
import 'session_manager.dart';
import 'homepage.dart';
import 'config.dart';
import 'api_service.dart';
import 'admin_auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.init(); // host is set before anything else runs

  try {
    await AudioService().initialize();
  } catch (e) {
    debugPrint('AudioService init error: $e');
  }

  UserProfile? savedProfile;
  try {
    savedProfile = await SessionManager.restoreSession();
  } catch (e) {
    debugPrint('SessionManager restore error: $e');
    savedProfile = null;
  }

  debugPrint('Restored profile: $savedProfile');

  // Same idea as the player session check above, but for admin: if there's
  // a saved admin token, a refresh (or fresh page load) while on the admin
  // side should land back on the dashboard instead of always falling
  // through to the player flow.
  bool hasAdminToken = false;
  try {
    final adminToken = await ApiService().getToken();
    hasAdminToken = adminToken != null && adminToken.isNotEmpty;
  } catch (e) {
    debugPrint('Admin token check error: $e');
  }

  runApp(MyApp(initialProfile: savedProfile, hasAdminToken: hasAdminToken));
}

class MyApp extends StatelessWidget {
  final UserProfile? initialProfile;
  final bool hasAdminToken;

  const MyApp({super.key, this.initialProfile, this.hasAdminToken = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        textTheme: const TextTheme().apply(
          fontSizeFactor: 1.0,
        ),
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
      home: hasAdminToken
          ? const AdminAuthGate()
          : (initialProfile != null
              ? HomePage(profile: initialProfile!)
              : const SplashScreen()),
    );
  }
}