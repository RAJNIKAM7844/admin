import 'package:admin_eggs/admin_home_screen.dart';
import 'package:admin_eggs/forgot.dart';
import 'package:admin_eggs/login.dart';
import 'package:admin_eggs/update.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://kwoxhpztkxzqetwanlxx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt3b3hocHp0a3h6cWV0d2FubHh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUxMjQyMTAsImV4cCI6MjA2MDcwMDIxMH0.jEIMSnX6-uEA07gjnQKdEXO20Zlpw4XPybfeLQr7W-M',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthCheck(),
      routes: {
        '/login': (context) => const AdminLoginPage(),
        '/admin_reset': (context) => const AdminForgotPasswordPage(),
        '/update': (context) => const UpdateRatePage(),
        '/home': (context) => const AdminHomeScreen(),
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.value(Supabase.instance.client.auth.currentSession),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D0221), Color(0xFF2A1B3D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Egg Admin',
                      style: GoogleFonts.roboto(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const AdminHomeScreen();
        }

        return const AdminLoginPage();
      },
    );
  }
}
