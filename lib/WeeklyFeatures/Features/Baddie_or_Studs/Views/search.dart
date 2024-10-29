// lib/Views/SearchScreen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/challenges.dart'; // Import the Challenge model
import '../Models/bottomnavigation.dart'; // Import the BottomNavigation widget
import '../Views/Participate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Models/ChallengeRankingPage.dart'; // For custom fonts
import '../Models/search_delegate.dart'; // Import the custom SearchDelegate
import 'ChallengeVoteScreen.dart'; // Import the new ChallengeVoteScreen

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  int _currentIndex = 1; // Set initial index to Search (index 1)

  void _showInformationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Information"),
          content: Text(
            "• The blue line shows how much time is left before the challenge ends.\n\n"
            "• You can either participate, view the ranking, or vote in a specific challenge.\n\n"
            "• If you try to participate but don't have enough uploads, go to your profile page to buy more uploads.\n\n"
            "• 10 dollars means 10 uploads.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Updated AppBar with a gradient background and search icon
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.info_outline, color: Colors.white),
          tooltip: 'Information',
          onPressed: _showInformationDialog,
        ),
        title: Text(
          'Challenges',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            tooltip: 'Search',
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(),
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purpleAccent, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      // Updated body with gradient background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('challenge').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.blueAccent,
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No challenges available',
                  style: TextStyle(color: Colors.black54),
                ),
              );
            }

            final challenges = snapshot.data!.docs.map((doc) {
              return Challenge.fromMap(
                  doc.data() as Map<String, dynamic>, doc.id);
            }).toList();

            // Delete expired challenges from Firestore
            challenges.forEach((challenge) {
              if (challenge.endDate.isBefore(DateTime.now())) {
                FirebaseFirestore.instance
                    .collection('challenge')
                    .doc(challenge.id)
                    .delete();
              }
            });

            // Filter out expired challenges
            final activeChallenges = challenges
                .where((challenge) => challenge.endDate.isAfter(DateTime.now()))
                .toList();

            if (activeChallenges.isEmpty) {
              return Center(
                child: Text(
                  'No active challenges available',
                  style: TextStyle(color: Colors.black54),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: activeChallenges.length,
              itemBuilder: (context, index) {
                final challenge = activeChallenges[index];
                return ChallengeBox(
                  key: ValueKey(challenge.id),
                  challenge: challenge,
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex, // Pass the current selected index
      ),
    );
  }
}

class ChallengeBox extends StatelessWidget {
  final Challenge challenge; // The Challenge instance

  const ChallengeBox({
    Key? key,
    required this.challenge,
  }) : super(key: key);

  // Default image URL path
  final String defaultImageURL =
      'lib/WeeklyFeatures/Assets/Images/Welcome_screen_background.webp';

  @override
  Widget build(BuildContext context) {
    // Determine the appropriate image provider
    ImageProvider backgroundImage;

    if (challenge.imageURL.isNotEmpty &&
        Uri.tryParse(challenge.imageURL)?.isAbsolute == true) {
      backgroundImage = NetworkImage(challenge.imageURL);
    } else {
      backgroundImage = AssetImage(defaultImageURL);
    }

    // Calculate progress
    DateTime now = DateTime.now();
    Duration totalDuration = challenge.endDate.difference(challenge.startDate);
    Duration elapsedDuration = now.difference(challenge.startDate);

    double progress = elapsedDuration.inSeconds / totalDuration.inSeconds;
    progress = progress.clamp(0.0, 1.0); // Ensure progress is between 0 and 1

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0), // Adjusted for sleek spacing
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // Added gradient background
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent.withOpacity(0.8),
            Colors.purpleAccent.withOpacity(0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image(
                image: backgroundImage,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              challenge.criteria,
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              '${challenge.startDate.toLocal().toString().split(' ')[0]} - ${challenge.endDate.toLocal().toString().split(' ')[0]}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                semanticLabel: 'Show more options',
              ),
              onPressed: () {
                // Show modal with background image and icons
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return ChallengeDetailModal(
                      challenge: challenge,
                      backgroundImage: backgroundImage,
                    );
                  },
                );
              },
            ),
          ),
          // New Row for Image Icon and Count
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Icon(
                  Icons.image,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  '${challenge.images}',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Progress bar indicating how close the end date is
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

class ChallengeDetailModal extends StatelessWidget {
  final Challenge challenge;
  final ImageProvider backgroundImage;

  const ChallengeDetailModal({
    Key? key,
    required this.challenge,
    required this.backgroundImage,
  }) : super(key: key);

  // Helper method to build the option buttons
  Widget _buildOptionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onPressed,
      int? count}) {
    return Column(
      children: [
        IconButton(
          icon: Icon(
            icon,
            size: 32,
            color: Colors.white,
          ),
          onPressed: onPressed,
        ),
        if (count != null)
          Text(
            '$count',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16.0),
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // Updated image with color filter for better contrast
          image: DecorationImage(
            image: backgroundImage,
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5), BlendMode.darken),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              challenge.criteria,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black54,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            // Icons with numbers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionButton(
                  context,
                  icon: Icons.leaderboard,
                  label: 'Ranking',
                  onPressed: () {
                    // Navigate to ChallengeRankingPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChallengeRankingPage(
                          challengeId: challenge.id,
                        ),
                      ),
                    );
                  },
                ),
                _buildOptionButton(
                  context,
                  icon: Icons.upload,
                  label: 'Participate',
                  onPressed: () {
                    // Navigate to Participate screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            Participate(challengeId: challenge.id),
                      ),
                    );
                  },
                ),
                _buildOptionButton(
                  context,
                  icon: Icons.thumb_up,
                  label: 'Vote',
                  onPressed: () {
                    // Navigate to ChallengeVoteScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChallengeVoteScreen(
                          challengeId: challenge.id,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
