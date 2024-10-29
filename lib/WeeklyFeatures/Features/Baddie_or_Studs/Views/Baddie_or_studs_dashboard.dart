// lib/WeeklyFeatures/Features/Baddie_or_Studs/Views/Dashboard.dart

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import necessary widgets and models
import '../Models/bottomnavigation.dart';
import '../Models/ChallengeRankingPage.dart';
import '../Models/RightRatingButton.dart';
import '../Models/LeftActionButton.dart';
import '../Views/Participate.dart';
import '../Models/DetailedPostView.dart';

class BaddiesOrStudsDashboard extends ConsumerStatefulWidget {
  @override
  ConsumerState<BaddiesOrStudsDashboard> createState() =>
      _BaddiesOrStudsDashboardState();
}

class _BaddiesOrStudsDashboardState
    extends ConsumerState<BaddiesOrStudsDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: UploadsPageView(),
      ),
      bottomNavigationBar: BottomNavigation(currentIndex: 0),
    );
  }
}

class UploadsPageView extends StatelessWidget {
  const UploadsPageView({Key? key}) : super(key: key);

  // Function to get uploads from Firestore
  Stream<QuerySnapshot> _getUploads() {
    return FirebaseFirestore.instance
        .collection('uploads') // Access the 'uploads' collection
        .orderBy('uploadedAt', descending: true) // Sort by upload time (newest first)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getUploads(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(child: Text("No images found"));
        }

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];

            // Extract the data from Firestore document
            final imageUrl = doc['imageURL'] as String? ?? '';
            final double rating = (doc['note'] is double)
                ? doc['note']
                : double.tryParse(doc['note'].toString()) ?? 0.0;
            final String challengeId = doc['challengeId'] as String? ?? '';
            final String uploadId = doc.id;

            return GestureDetector(

              child: UploadPage(
                imageUrl: imageUrl,
                rating: rating,
                challengeId: challengeId,
                uploadId: uploadId,
              ),
            );
          },
        );
      },
    );
  }
}

class UploadPage extends StatefulWidget {
  final String imageUrl;
  final double rating;
  final String challengeId;
  final String uploadId; // Added uploadId

  const UploadPage({
    Key? key,
    required this.imageUrl,
    required this.rating,
    required this.challengeId,
    required this.uploadId,
  }) : super(key: key);

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  double _currentRating = 0.0;
  String _criteria = '';
  bool _isSubmitting = false; // Track if a rating submission is in progress
  bool _hasVoted = false; // Track if the user has voted

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
    _checkIfUserHasVoted(); // Check if user has already voted
  }

  // Fetch challenge criteria when needed
  Future<void> _fetchChallengeCriteria() async {
    try {
      DocumentSnapshot challengeDoc = await FirebaseFirestore.instance
          .collection('challenge')
          .doc(widget.challengeId)
          .get();

      if (challengeDoc.exists) {
        String criteria = challengeDoc['criteria'] ?? 'No Criteria Available';
        setState(() {
          _criteria = criteria.toUpperCase(); // Display in uppercase
        });
      } else {
        setState(() {
          _criteria = 'CHALLENGE NOT FOUND';
        });
      }
    } catch (e) {
      developer.log('Error fetching challenge criteria: $e');
      setState(() {
        _criteria = 'ERROR FETCHING CRITERIA';
      });
    }
  }

  // Check if the user has already voted
  Future<void> _checkIfUserHasVoted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // User not logged in
      setState(() {
        _hasVoted = false;
      });
      return;
    }

    try {
      DocumentSnapshot voteDoc = await FirebaseFirestore.instance
          .collection('uploads')
          .doc(widget.uploadId)
          .collection('votes')
          .doc(user.uid)
          .get();

      setState(() {
        _hasVoted = voteDoc.exists;
      });
    } catch (e) {
      developer.log('Error checking user vote: $e');
      setState(() {
        _hasVoted = false;
      });
    }
  }

  // Callback functions for LeftActionButton
  void _handleParticipate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Participate(challengeId: widget.challengeId),
      ),
    );
  }

  void _showInformationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Information"),
          content: Text(
            "• You can only vote once per picture.\n\n"
                "• If you click on the left button, you will access:\n"
                "  - Comments\n"
                "  - Like\n"
                "  - Participate (allows you to join a challenge)\n"
                "  - Ranking\n"
                "  - Vote Distribution",
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

  void _handleRanking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeRankingPage(challengeId: widget.challengeId),
      ),
    );
  }

  // Callback function for RightRatingButton
  void _handleRatingSelected(double rating) async {
    setState(() {
      _isSubmitting = true; // Start submitting
    });
    developer.log('Rating selected: $rating');
    await _submitRating(rating); // Submit rating to Firestore
    setState(() {
      _isSubmitting = false; // Submission complete
      _hasVoted = true; // User has now voted
    });
  }

  // Function to get the dynamic color based on rating
  Color _getRatingColor(double rating) {
    // Adjusted color calculation to enhance visibility and consistency
    if (rating <= 5.0) {
      double green = (rating / 5.0) * 255;
      return Color.fromARGB(255, 255, green.toInt(), 0);
    } else {
      double red = ((10.0 - rating) / 5.0) * 255;
      return Color.fromARGB(255, red.toInt(), 255, 0);
    }
  }

  // Submit rating to Firestore with updated weighted calculation
  Future<void> _submitRating(double userRating) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // User not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to vote.')),
      );
      return;
    }

    final uploadRef = FirebaseFirestore.instance.collection('uploads').doc(widget.uploadId);
    final voteRef = uploadRef.collection('votes').doc(user.uid);
    final challengeImageRef = FirebaseFirestore.instance
        .collection('challenge')
        .doc(widget.challengeId)
        .collection('images')
        .doc(widget.uploadId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // **1. Read All Required Documents First**
        // Read voteRef
        DocumentSnapshot voteSnapshot = await transaction.get(voteRef);
        if (voteSnapshot.exists) {
          // User has already voted
          throw Exception('You have already voted for this image.');
        }

        // Read uploadRef
        DocumentSnapshot uploadSnapshot = await transaction.get(uploadRef);
        if (!uploadSnapshot.exists) {
          throw Exception('Upload does not exist.');
        }

        // Read challengeImageRef
        DocumentSnapshot challengeImageSnapshot = await transaction.get(challengeImageRef);

        // **2. Process Upload Document**
        Map<String, dynamic> uploadData = uploadSnapshot.data() as Map<String, dynamic>;

        double originalNote;
        if (uploadData.containsKey('originalNote')) {
          originalNote = uploadData['originalNote'] is double
              ? uploadData['originalNote']
              : double.tryParse(uploadData['originalNote'].toString()) ?? 0.0;
        } else {
          originalNote = uploadData['note'] is double
              ? uploadData['note']
              : double.tryParse(uploadData['note'].toString()) ?? 0.0;
        }

        // Get current voteCount and totalVoteValue
        int voteCount = uploadData['voteCount'] ?? 0;
        double totalVoteValue = uploadData['totalVoteValue']?.toDouble() ?? 0.0;

        // Calculate new vote count and total vote value
        double newTotalVoteValue = totalVoteValue + userRating;
        int newVoteCount = voteCount + 1;

        // Calculate average user rating with the new vote
        double newAverageUserRating = newTotalVoteValue / newVoteCount;

        // Calculate user weight percentage based on new vote count
        double userWeightPercentage = _calculateUserWeightPercentage(newVoteCount);

        // Calculate new overall rating with original note contributing 40%
        double newNote = (originalNote * 0.4 + newAverageUserRating * userWeightPercentage) / (0.4 + userWeightPercentage);

        // Optional: Clamp the newNote to a maximum value (assuming 10.0 scale)
        newNote = newNote.clamp(0.0, 10.0);

        // **3. Process Challenge Image Document**
        double challengeOriginalNote;
        if (challengeImageSnapshot.exists) {
          Map<String, dynamic> challengeImageData = challengeImageSnapshot.data() as Map<String, dynamic>;

          if (challengeImageData.containsKey('originalNote')) {
            challengeOriginalNote = challengeImageData['originalNote'] is double
                ? challengeImageData['originalNote']
                : double.tryParse(challengeImageData['originalNote'].toString()) ?? 0.0;
          } else {
            challengeOriginalNote = challengeImageData['note'] is double
                ? challengeImageData['note']
                : double.tryParse(challengeImageData['note'].toString()) ?? 0.0;
          }
        } else {
          // If the challenge image document doesn't exist, use the upload's originalNote
          challengeOriginalNote = originalNote;
        }

        // Get current voteCount and totalVoteValue for challenge images
        int challengeVoteCount = challengeImageSnapshot.exists
            ? (challengeImageSnapshot['voteCount'] ?? 0)
            : 0;
        double challengeTotalVoteValue = challengeImageSnapshot.exists
            ? (challengeImageSnapshot['totalVoteValue']?.toDouble() ?? 0.0)
            : 0.0;

        // Calculate new vote count and total vote value for challenge images
        double newChallengeTotalVoteValue = challengeTotalVoteValue + userRating;
        int newChallengeVoteCount = challengeVoteCount + 1;

        // Calculate average user rating for challenge images with the new vote
        double newChallengeAverageUserRating = newChallengeTotalVoteValue / newChallengeVoteCount;

        // Calculate user weight percentage for challenge images
        double challengeUserWeightPercentage = _calculateUserWeightPercentage(newChallengeVoteCount);

        // Calculate new overall rating for challenge images
        double newChallengeNote = (challengeOriginalNote * 0.4 + newChallengeAverageUserRating * challengeUserWeightPercentage) / (0.4 + challengeUserWeightPercentage);

        // Optional: Clamp the newChallengeNote to a maximum value (assuming 10.0 scale)
        newChallengeNote = newChallengeNote.clamp(0.0, 10.0);

        // **4. Perform All Write Operations**
        // Update uploads document
        transaction.update(uploadRef, {
          'note': newNote,
          'voteCount': newVoteCount,
          'totalVoteValue': newTotalVoteValue,
        });

        // Update or set challenge images document
        if (!challengeImageSnapshot.exists) {
          // Create the challenge image document
          transaction.set(challengeImageRef, {
            'originalNote': challengeOriginalNote,
            'note': newChallengeNote,
            'voteCount': 1,
            'totalVoteValue': userRating,
            'uploadedAt': uploadData['uploadedAt'] ?? FieldValue.serverTimestamp(),
          });
        } else {
          // Update the challenge image document
          transaction.update(challengeImageRef, {
            'note': newChallengeNote,
            'voteCount': newChallengeVoteCount,
            'totalVoteValue': newChallengeTotalVoteValue,
          });
        }

        // Add vote document to track user's vote
        transaction.set(voteRef, {
          'userId': user.uid,
          'rating': userRating,
          'votedAt': FieldValue.serverTimestamp(),
        });
      });

      // Provide feedback to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your vote has been submitted!')),
      );
    } catch (e) {
      developer.log('Error submitting rating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting vote: ${e.toString()}')),
      );
    }
  }

  // Function to calculate user weight percentage based on vote count
  double _calculateUserWeightPercentage(int voteCount) {
    if (voteCount <= 0) {
      return 0.0;
    } else if (voteCount <= 100) {
      return (voteCount / 100) * 0.6;
    } else {
      return 0.6;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double _padding = 16.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Main image without rounded corners and background color
        Positioned.fill(
          child: Image.network(
            widget.imageUrl, // Ensure the image URL remains static
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(child: Text('Failed to load image'));
            },
          ),
        ),
        // Challenge criteria at the top
        Positioned(
          top: _padding,
          left: _padding,
          right: _padding,
          child: FutureBuilder(
            future: _fetchChallengeCriteria(),
            builder: (context, snapshot) {
              return Center(
                child: Text(
                  'CHALLENGE CRITERIA: $_criteria',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: _getRatingColor(_currentRating), // Update color based on currentRating
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
         top: _padding,
         right: _padding,
         child: IconButton(
          icon: Icon(Icons.info_outline, color: Colors.white),
        onPressed: () {
         _showInformationDialog();
        },
      ),) ,
        // Rectangular rating display at the bottom of the image
        Positioned(
          bottom: _padding * 2,
          left: _padding,
          right: _padding,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _getRatingColor(_currentRating).withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 5,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: _isSubmitting
                  ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              )
                  : Text(
                'RATING: ${_currentRating.toStringAsFixed(1)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        // RightRatingButton for selecting the rating
        Positioned(
          bottom: _padding + 60, // Adjusted to be above the bottom navigation
          right: _padding, // Aligned to the right edge with some padding
          child: RightRatingButton(
            uploadId: widget.uploadId,
            currentRating: _currentRating,
            onRatingSelected: _handleRatingSelected,
            isSubmitting: _isSubmitting, // Pass isSubmitting to disable button if needed
            hasVoted: _hasVoted, // Pass hasVoted to disable if needed
          ),
        ),
        // LeftActionButton for other actions (like, comment, participate)
        Positioned(
          bottom: _padding + 60, // Adjusted to be above the bottom navigation
          left: _padding, // Aligned to the left edge with some padding
          child: LeftActionButton(
            uploadId: widget.uploadId,
            onParticipate: _handleParticipate,
            onRanking: _handleRanking,
          ),
        ),
      ],
    );
  }
}
