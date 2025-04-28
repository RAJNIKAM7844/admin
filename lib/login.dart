import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  static const String _emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const int _minPasswordLength = 8;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_validateInputs(email, password)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simplified query: select only email
      print('Querying admins table for email: $email');
      final adminCheck = await Supabase.instance.client
          .from('admins')
          .select('email') // Only fetch email column
          .eq('email', email)
          .maybeSingle();

      if (adminCheck == null) {
        print('No admin found for email: $email');
        throw Exception('No admin account found for this email');
      }

      print('Admin email found, attempting sign-in');
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        print('Sign-in failed: Invalid credentials');
        throw Exception('Invalid credentials');
      }

      print('Sign-in successful, navigating to admin_home');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      print('AuthException: ${e.message}');
      _showSnackBar('Login failed: ${e.message}');
    } catch (e) {
      print('Error: $e');
      _showSnackBar('Login failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateInputs(String email, String password) {
    if (email.isEmpty) {
      _showSnackBar('Please enter your email');
      return false;
    }

    if (!RegExp(_emailPattern).hasMatch(email)) {
      _showSnackBar('Please enter a valid email address');
      return false;
    }

    if (password.isEmpty) {
      _showSnackBar('Please enter your password');
      return false;
    }

    if (password.length < _minPasswordLength) {
      _showSnackBar('Password must be at least $_minPasswordLength characters');
      return false;
    }

    return true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Admin Login",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Sign in to access admin panel",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(
                    Icons.email,
                    "Email Address",
                    controller: _emailController,
                  ),
                  _buildTextField(
                    Icons.lock,
                    "Password",
                    obscureText: _obscurePassword,
                    controller: _passwordController,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/admin_reset'),
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Sign In",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    IconData icon,
    String hint, {
    bool obscureText = false,
    required TextEditingController controller,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 50,
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
            suffixIcon: suffixIcon,
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          ),
        ),
      ),
    );
  }
}
