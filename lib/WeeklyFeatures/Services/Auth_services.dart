import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/Users.dart'; // Updated import
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService() {
    // Listen for FCM token refresh and update Firestore
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': newToken,
        });
      }
    });
  }

  /// Sign Up with Email and Password
  Future<void> signUpWithEmail(
      String email,
      String password,
      String username, {
        String? bio,
      }) async {
    try {
      // Create user with email and password
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Create a UserModel instance with onboarding flag set to false
        UserModel userModel = UserModel(
          id: user.uid,
          username: username,
          photoUrl: user.photoURL,
          bio: bio ?? '',
          ul: 2, // Initialize UL with 2 uploads left
          hasCompletedOnboarding: false, // New user hasn't completed onboarding
        );

        // Store user information in Firestore
        await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

        // Fetch and store the FCM token
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': fcmToken,
          });
        }
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Sign In with Email and Password
  Future<void> signInWithEmail(String email, String password) async {
    try {
      // Sign in user with email and password
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Fetch user data from Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          // If user document does not exist, create it with minimal data
          UserModel userModel = UserModel(
            id: user.uid,
            username: user.displayName ?? 'Unnamed User',
            photoUrl: user.photoURL,
            bio: '',
          );
          await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
        }

        // Fetch and store the FCM token
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': fcmToken,
          });
        }
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Sign In with Google
  Future<void> signInWithGoogle() async {
    try {
      // Sign out any existing Google Sign-In session
      await _googleSignIn.signOut();

      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Create a new credential
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google user credentials
        UserCredential result = await _auth.signInWithCredential(credential);

        User? user = result.user;

        if (user != null) {
          // Check if user document exists
          DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

          if (!userDoc.exists) {
            // If not, create it with data from Google account and set onboarding flag
            UserModel userModel = UserModel(
              id: user.uid,
              username: user.displayName ?? 'Unnamed User',
              photoUrl: user.photoURL,
              bio: '', // Google doesn't provide bio, so we'll leave it empty
              ul: 2, // Initialize UL with 2 uploads left
              hasCompletedOnboarding: false, // New user hasn't completed onboarding
            );

            await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
          }

          // Fetch and store the FCM token
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await _firestore.collection('users').doc(user.uid).update({
              'fcmToken': fcmToken,
            });
          }
        }
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Get Current UserModel
  Future<UserModel?> getCurrentUserModel() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>, user.uid);
      }
    }
    return null;
  }

  /// Update Onboarding Status
  Future<void> setOnboardingCompleted(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'hasCompletedOnboarding': true,
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
