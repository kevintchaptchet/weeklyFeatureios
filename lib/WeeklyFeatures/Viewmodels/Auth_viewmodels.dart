// Updated lib/auth_view_model.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../services/Auth_services.dart'; // Ensure this path is correct
import '../Routes/Route.dart';
import '../Models/Users.dart'; // Import the UserModel

// Provider for AuthService

// Provider for AuthViewModel
final authViewModelProvider = ChangeNotifierProvider<AuthViewModel>((ref) => AuthViewModel(ref));

// AuthViewModel Class
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  // Holds the current user's UserModel
  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  // Constructor: Initializes AuthService and fetches current user if already signed in
  AuthViewModel(Ref ref) : _authService = ref.read(authServiceProvider) {
    // Initialize user data if already authenticated
    initializeUser();
  }

  /// Initializes the user by fetching the current user's UserModel
  Future<void> initializeUser() async {
    try {
      UserModel? user = await _authService.getCurrentUserModel();
      if (user != null) {
        _userModel = user;
        notifyListeners();
      }
    } catch (e) {
      // Handle errors silently or log them
      print('Error initializing user: $e');
    }
  }

  /// Handles Sign Up with Email
  ///
  /// [email], [password], and [username] are required.
  /// [bio] is optional.
  Future<void> signUpWithEmail(
      BuildContext context,
      String email,
      String password,
      String username, {
        String? bio,
      }) async {
    try {
      await _authService.signUpWithEmail(email, password, username, bio: bio);

      // After sign-up, fetch the current user model
      UserModel? user = await _authService.getCurrentUserModel();

      if (user != null) {
        _userModel = user;
        notifyListeners();

        // Navigate to presentation screen without email verification
        Navigator.pushReplacementNamed(context, AppRoutes.presentationScreen);
      } else {
        throw Exception('Authentication failed');
      }
    } catch (e) {
      _showError(context, e.toString());
    }
  }

  /// Handles Sign In with Email
  ///
  /// [email] and [password] are required.
  Future<void> signInWithEmail(
      BuildContext context,
      String email,
      String password,
      ) async {
    try {
      await _authService.signInWithEmail(email, password);

      // After sign-in, fetch the current user model
      UserModel? user = await _authService.getCurrentUserModel();

      if (user != null) {
        _userModel = user;
        notifyListeners();

        // Navigate to presentation screen without email verification
        Navigator.pushReplacementNamed(context, AppRoutes.presentationScreen);
      } else {
        throw Exception('Authentication failed');
      }
    } catch (e) {
      _showError(context, e.toString());
    }
  }

  /// Handles Sign In with Google
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      await _authService.signInWithGoogle();

      // After sign-in, fetch the current user model
      UserModel? user = await _authService.getCurrentUserModel();

      if (user != null) {
        _userModel = user;
        notifyListeners();

        // For Google sign-in, email is already verified
        Navigator.pushReplacementNamed(context, AppRoutes.presentationScreen);
      } else {
        throw Exception('Authentication failed');
      }
    } catch (e) {
      _showError(context, e.toString());
    }
  }

  /// Handles Sign Out
  Future<void> signOut(BuildContext context) async {
    try {
      await _authService.signOut();
      _userModel = null;
      notifyListeners();
      Navigator.pushReplacementNamed(context, AppRoutes.welcomeScreen);
    } catch (e) {
      _showError(context, e.toString());
    }
  }

  /// Displays an error message using a SnackBar
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
final authServiceProvider = Provider<AuthService>((ref) => AuthService());