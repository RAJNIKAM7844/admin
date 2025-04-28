import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminForgotPasswordPage extends StatefulWidget {
  const AdminForgotPasswordPage({super.key});

  @override
  State<AdminForgotPasswordPage> createState() =>
      _AdminForgotPasswordPageState();
}

class _AdminForgotPasswordPageState extends State<AdminForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  static const String _emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (!_validateInput(email)) return;
    setState(() => _isLoading = true);
    try {
      print('Checking admins table for email: $email');
      final adminCheck = await Supabase.instance.client
          .from('admins')
          .select('email')
          .eq('email', email)
          .maybeSingle();
      if (adminCheck == null) {
        print('No admin found for email: $email');
        throw Exception('No admin account found for this email');
      }
      print('Admin found, sending reset email');
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      _showSnackBar('Password reset email sent! Check your inbox');
      if (mounted) Navigator.pop(context);
    } on AuthException catch (e) {
      print('AuthException: ${e.message}');
      _showSnackBar('Error: ${e.message}');
    } catch (e) {
      print('Error: $e');
      _showSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateInput(String email) {
    if (email.isEmpty) {
      _showSnackBar('Please enter your email');
      return false;
    }

    if (!RegExp(_emailPattern).hasMatch(email)) {
      _showSnackBar('Please enter a valid email address');
      return false;
    }

    return true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Admin Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Admin Reset Password",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Enter your email to receive a password reset link",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                _buildTextField(
                  Icons.email,
                  "Email Address",
                  controller: _emailController,
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
                  onPressed: _isLoading ? null : _resetPassword,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Send Reset Link",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    IconData icon,
    String hint, {
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 50,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
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
