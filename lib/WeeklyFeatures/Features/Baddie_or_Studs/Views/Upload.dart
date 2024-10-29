import 'package:flutter/material.dart';
import 'package:weekly_features/WeeklyFeatures/Features/Baddie_or_Studs/Routes/routes.dart';
import '../Models/bottomnavigation.dart'; // Import the BottomNavigation widget
import 'package:google_fonts/google_fonts.dart'; // For custom fonts

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  int _currentIndex = 3; // Set initial index to Upload (index 3)

  // Define a consistent padding value
  final double _padding = 16.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Apply a gradient background to the Scaffold body
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
            // Dismiss keyboard or focus when tapping outside
            onTap: () => FocusScope.of(context).unfocus(),
            child: Padding(
              padding: EdgeInsets.all(_padding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title Section
                  Text(
                    'What would you like to do?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 26,
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
                  ),
                  SizedBox(height: _padding * 1.5),

                  // Participate in a Challenge Button
                  _buildActionButton(
                    icon: Icons.join_inner,
                    label: 'Participate in a Challenge',
                    color: Colors.greenAccent,
                    onPressed: () {
                      // Navigate to the Participate in a Challenge screen
                      Navigator.pushNamed(context, BaddieRoutes.search); // Replace with actual route name
                    },
                  ),
                  SizedBox(height: _padding),

                  // Create a Challenge Button
                  _buildActionButton(
                    icon: Icons.create,
                    label: 'Create a Challenge',
                    color: Colors.orangeAccent,
                    onPressed: () {
                      // Navigate to the Create a Challenge screen
                      Navigator.pushNamed(context, BaddieRoutes.create_challenge); // Replace with actual route name
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // Include BottomNavigation
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex, // Pass the current selected index
      ),
    );
  }

  // Helper method to build styled action buttons with icons
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.9),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withAlpha(50),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            children: [
              // Icon Section
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(12),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              SizedBox(width: 20),
              // Label Section
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
