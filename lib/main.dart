import 'package:admin_eggs/admin_home_screen.dart';
import 'package:admin_eggs/calendar.dart';
import 'package:admin_eggs/forgot.dart';
import 'package:admin_eggs/login.dart';
import 'package:admin_eggs/update.dart';
import 'package:flutter/material.dart';
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
      home: const AuthCheck(), // Use AuthCheck as the home widget
      routes: {
        '/login': (context) => const AdminLoginPage(),
        '/admin_reset': (context) => const AdminForgotPasswordPage(),
        '/update': (context) => const UpdateRatePage(),
        '/home': (context) => const AdminHomeScreen(),
      },
    );
  }
}

// Widget to check authentication state and navigate accordingly
class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.value(Supabase.instance.client.auth.currentSession),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while checking the session
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If there's an active session and a user, go to AdminHomeScreen
        if (snapshot.hasData && snapshot.data != null) {
          return const AdminHomeScreen();
        }

        // Otherwise, go to AdminLoginPage
        return const AdminLoginPage();
      },
    );
  }
}
