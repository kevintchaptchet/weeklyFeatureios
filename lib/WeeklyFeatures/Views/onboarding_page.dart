// File: lib/Views/onboarding_page.dart

import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weekly_features/WeeklyFeatures/Views/Welcome.dart';
import '../services/auth_services.dart';
import '../Viewmodels/Auth_viewmodels.dart';
import 'home.dart'; // Import your HomePage

class OnboardingPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);

    List<PageViewModel> pages = [
      PageViewModel(
        title: "Welcome to WeeklyFeature",
        body:
        "This is a special kind of social network where features are released every week.",
        image: _buildImage('lib/WeeklyFeatures/Assets/Images/welcome.webp'),
        decoration: _getPageDecoration(),
      ),
      PageViewModel(
        title: "What is a Feature?",
        body:
        "A feature is an entire app or just a mini app that is fun and does something very specific like rating pictures or bringing you back to your past by making you feel a certain way.",
        image: _buildImage('lib/WeeklyFeatures/Assets/Images/features.webp'),
        decoration: _getPageDecoration(),
      ),
      PageViewModel(
        title: "Explore and Enjoy",
        body:
        "Feel free to check them all. Your safety and privacy are our top priorities. We've implemented robust security measures to protect your data and ensure a safe experience.",
        image: _buildImage('lib/WeeklyFeatures/Assets/Images/explore.webp'),
        decoration: _getPageDecoration(),
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purpleAccent, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: IntroductionScreen(
          pages: pages,
          onDone: () async {
            // When done, mark onboarding as completed and navigate to Home
            final user = await authService.getCurrentUserModel();
            if (user != null) {
              await authService.setOnboardingCompleted(user.id);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => WelcomeScreen()),
              );
            }
          },
          onSkip: () async {
            // When skipped, mark onboarding as completed and navigate to Home
            final user = await authService.getCurrentUserModel();
            if (user != null) {
              await authService.setOnboardingCompleted(user.id);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => HomePage()),
              );
            }
          },
          showSkipButton: true,
          skip: Text(
            "Skip",
            style: GoogleFonts.roboto(color: Colors.white70),
          ),
          next: Icon(Icons.arrow_forward, color: Colors.white70),
          done: Text(
            "Done",
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          dotsDecorator: DotsDecorator(
            activeColor: Colors.white,
            size: Size(10.0, 10.0),
            activeSize: Size(22.0, 10.0),
            activeShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
          ),
          globalBackgroundColor: Colors.transparent, // Use gradient background
          // Removed 'skipFlex' and 'nextFlex' parameters
        ),
      ),
    );
  }

  /// Helper method to build images for the slides
  Widget _buildImage(String assetName) {
    return Align(
      child: Image.asset(assetName, width: 350),
      alignment: Alignment.bottomCenter,
    );
  }

  /// Define the decoration for each page
  PageDecoration _getPageDecoration() {
    return PageDecoration(
      titleTextStyle: GoogleFonts.pacifico(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyTextStyle: GoogleFonts.roboto(
        fontSize: 18,
        color: Colors.white70,
      ),
      // Removed 'descriptionPadding' parameter
      imagePadding: EdgeInsets.all(24),
      pageColor: Colors.transparent, // Transparent to show gradient
    );
  }
}
