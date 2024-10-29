import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../routes/route.dart'; // Make sure to import your routes

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _positionAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _animationController = AnimationController(
      duration: Duration(seconds: 4), // Animation lasts 4 seconds
      vsync: this,
    );

    // Define the scale animation (scaling up the text)
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ),
    );

    // Define the fade animation (fade in)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ),
    );

    // Define the position animation (slide up)
    _positionAnimation = Tween<Offset>(
      begin: Offset(0.0, 0.5), // Starts below the center
      end: Offset(0.0, 0.0),   // Ends at the center
    ).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ),
    );

    // Start the animation
    _animationController!.forward();

    // Navigate to the Welcome Screen after 5 seconds
    Timer(Duration(seconds: 5), () {
      Navigator.of(context).pushReplacementNamed(AppRoutes.welcomeScreen);
    });
  }

  @override
  void dispose() {
    _animationController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use AnimatedBuilder to rebuild the widget when the animation changes
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
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController!,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation!.value,
                child: SlideTransition(
                  position: _positionAnimation!,
                  child: Transform.scale(
                    scale: _scaleAnimation!.value,
                    child: child,
                  ),
                ),
              );
            },
            child: Text(
              'WEEKLY FEATURES',
              style: GoogleFonts.pacifico(
                fontSize: 48,
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
          ),
        ),
      ),
    );
  }
}
