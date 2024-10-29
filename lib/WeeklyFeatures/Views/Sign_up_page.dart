// Updated lib/views/sign_up.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Viewmodels/Auth_viewmodels.dart';
import 'package:google_fonts/google_fonts.dart'; // For custom fonts
import 'onboarding_page.dart'; // Import the OnboardingPage
import 'home.dart'; // Import the HomePage

class SignUpPage extends ConsumerStatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // Dispose controllers to free resources
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = ref.watch(authViewModelProvider);

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
              child: Form(
                key: _formKey, // Assign the form key
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      'Create Account',
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
                    // Username Input
                    _buildInputField(
                      controller: _usernameController,
                      label: 'Username',
                      hint: 'Enter your username',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    // Email Input
                    _buildInputField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter your email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    // Password Input
                    _buildInputField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter your password',
                      icon: Icons.lock,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    // Bio Input (Optional)
                    _buildInputField(
                      controller: _bioController,
                      label: 'Bio',
                      hint: 'Tell us about yourself (optional)',
                      icon: Icons.info_outline,
                      maxLines: 3,
                      validator: (value) {
                        if (value != null && value.length > 150) {
                          return 'Bio cannot exceed 150 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 40),
                    // Sign Up Button
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          // If the form is valid, proceed with sign-up
                          await authViewModel.signUpWithEmail(
                            context,
                            _emailController.text.trim(),
                            _passwordController.text,
                            _usernameController.text.trim(),
                            bio: _bioController.text.trim().isNotEmpty
                                ? _bioController.text.trim()
                                : null,
                          );
                        }
                      },
                      child: Text(
                        'Sign Up',
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
                    // Already have an account?
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Navigate back to sign-in page
                      },
                      child: Text(
                        'Already have an account? Sign In',
                        style: GoogleFonts.roboto(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method to build input fields with consistent styling
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
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
      validator: validator,
    );
  }
}
