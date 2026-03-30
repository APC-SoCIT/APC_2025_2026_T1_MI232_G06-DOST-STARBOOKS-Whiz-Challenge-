import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'audio_service.dart';
import 'session_manager.dart';
import 'homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AudioService().initialize();

  // ── Startup route decision ──────────────────────────────────────────────
  //
  //  Active session found  →  HomePage     (logged-in user refreshed the page)
  //  No session            →  SplashScreen (first open, after logout, or fresh tab)
  //
  //  This means:
  //   • First ever open / type localhost   → SplashScreen ✅
  //   • Refresh while logged in            → HomePage     ✅
  //   • Logout then refresh                → SplashScreen ✅
  //   • Open a new tab                     → SplashScreen ✅

  final savedProfile = await SessionManager.restoreSession();

  runApp(MyApp(initialProfile: savedProfile));
}

class MyApp extends StatelessWidget {
  final UserProfile? initialProfile;

  const MyApp({super.key, this.initialProfile});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      home: initialProfile != null
          ? HomePage(profile: initialProfile!)
          : const SplashScreen(),
    );
  }
}