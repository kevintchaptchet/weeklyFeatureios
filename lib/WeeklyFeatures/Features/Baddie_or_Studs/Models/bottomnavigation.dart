import 'package:flutter/material.dart';
import '../Routes/routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weekly_features/WeeklyFeatures/Routes/Route.dart';// For custom fonts

class BottomNavigation extends StatelessWidget {
  final int currentIndex; // Current selected index

  // Constructor to receive the currentIndex
  BottomNavigation({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    // Define the color palette
    final Color activeColor = Colors.white;
    final Color inactiveColor = Colors.white70;

    // Define gradient for background
    final LinearGradient backgroundGradient = LinearGradient(
      colors: [Colors.purpleAccent, Colors.blueAccent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: backgroundGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home,
                color: currentIndex == 0 ? activeColor : inactiveColor),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search,
                color: currentIndex == 1 ? activeColor : inactiveColor),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person,
                color: currentIndex == 2 ? activeColor : inactiveColor),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file,
                color: currentIndex == 3 ? activeColor : inactiveColor),
            label: 'Upload',
          ),
        ],
        currentIndex: currentIndex,
        selectedItemColor: activeColor,
        unselectedItemColor: inactiveColor,
        selectedLabelStyle: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.roboto(),
        onTap: (int index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, AppRoutes.Baddies_or_studs);
              break;
            case 1:
              Navigator.pushNamed(context, BaddieRoutes.search);
              break;
            case 2:
              Navigator.pushNamed(context, BaddieRoutes.profile);
              break;
            case 3:
              Navigator.pushNamed(context, BaddieRoutes.upload);
              break;
          }
        },
      ),
    );
  }
}
