// Updated lib/views/sign_in.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Viewmodels/Auth_viewmodels.dart';
import 'package:google_fonts/google_fonts.dart'; // For custom fonts

class SignInPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authViewModel = ref.watch(authViewModelProvider);

    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      // Apply a gradient background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purpleAccent, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            // Dismiss keyboard when tapping outside
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    'Welcome Back',
                    style: GoogleFonts.pacifico(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 8.0,
                          color: Colors.black26,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  // Email Input
                  _buildInputField(
                    controller: emailController,
                    label: 'Email',
                    hint: 'Enter your email',
                    icon: Icons.email,
                  ),
                  SizedBox(height: 20),
                  // Password Input
                  _buildInputField(
                    controller: passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    icon: Icons.lock,
                    obscureText: true,
                  ),
                  SizedBox(height: 40),
                  // Sign In Button
                  ElevatedButton(
                    onPressed: () async {
                      await authViewModel.signInWithEmail(
                        context,
                        emailController.text.trim(),
                        passwordController.text,
                      );
                    },
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black87,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Don't have an account?
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/SignUp'); // Replace with your sign-up route
                    },
                    child: Text(
                      "Don't have an account? Sign Up",
                      style: GoogleFonts.roboto(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Continue with Google Button
                  ElevatedButton.icon(
                    onPressed: () async {
                      await authViewModel.signInWithGoogle(context);
                    },
                    icon: Icon(Icons.login, color: Colors.black87),
                    label: Text(
                      'Continue with Google',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
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

  // Helper method to build input fields with consistent styling
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.roboto(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: GoogleFonts.roboto(color: Colors.white70),
        hintText: hint,
        hintStyle: GoogleFonts.roboto(color: Colors.white54),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white70),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
