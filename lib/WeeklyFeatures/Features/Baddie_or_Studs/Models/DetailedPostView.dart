// lib/Models/DetailedPostView.dart

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Removed share_plus import as it's no longer needed
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Import necessary widgets and models
import '../Models/bottomnavigation.dart';
import '../Models/ChallengeRankingPage.dart';
import '../Models/RightRatingButton.dart';
import '../Models/LeftActionButton.dart';
import '../Views/Participate.dart';

class DetailedPostView extends StatefulWidget {
  final String imageUrl;
  final double rating;
  final String challengeId;
  final String uploadId;
  final int initialIndex; // Existing parameter
  final int rank; // Existing required parameter

  const DetailedPostView({
    Key? key,
    required this.imageUrl,
    required this.rating,
    required this.challengeId,
    required this.uploadId,
    this.initialIndex = 0, // Optional with default
    this.rank = 0, // Make rank optional with default value
  }) : super(key: key);

  @override
  _DetailedPostViewState createState() => _DetailedPostViewState();
}


class _DetailedPostViewState extends State<DetailedPostView> {
  double _currentRating = 0.0;
  String _criteria = '';
  bool _isSubmitting = false;
  bool _hasVoted = false;

  List<DocumentSnapshot> allPosts = [];
  late PageController _pageController;
  late int currentPageIndex;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
    currentPageIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentPageIndex);
    _fetchAllUserPosts();
    _fetchChallengeCriteria();
    _checkIfUserHasVoted();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Fetches all posts by the user
  Future<void> _fetchAllUserPosts() async {
    try {
      // Fetch all posts by the user based on 'userId'
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('uploads')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
          .orderBy('uploadedAt', descending: true)
          .get();

      setState(() {
        allPosts = snapshot.docs;
      });
    } catch (e) {
      developer.log('Error fetching all user posts: $e');
      // Optionally, handle the error (e.g., show a message to the user)
    }
  }

  /// Fetch challenge criteria
  Future<void> _fetchChallengeCriteria() async {
    try {
      DocumentSnapshot challengeDoc = await FirebaseFirestore.instance
          .collection('challenge')
          .doc(widget.challengeId)
          .get();

      if (challengeDoc.exists) {
        String criteria = challengeDoc['criteria'] ?? 'No Criteria Available';
        setState(() {
          _criteria = criteria.toUpperCase();
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

  /// Check if the user has already voted
  Future<void> _checkIfUserHasVoted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
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

  /// Callback functions for LeftActionButton
  void _handleParticipate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Participate(challengeId: widget.challengeId),
      ),
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

  /// Callback function for RightRatingButton
  void _handleRatingSelected(double rating) async {
    setState(() {
      _isSubmitting = true;
    });
    developer.log('Rating selected: $rating');
    await _submitRating(rating);
    setState(() {
      _isSubmitting = false;
      _hasVoted = true;
    });
  }

  /// Function to get the dynamic color based on rating
  Color _getRatingColor(double rating) {
    if (rating <= 5.0) {
      double green = (rating / 5.0) * 255;
      return Color.fromARGB(255, 255, green.toInt(), 0);
    } else {
      double red = ((10.0 - rating) / 5.0) * 255;
      return Color.fromARGB(255, red.toInt(), 255, 0);
    }
  }

  /// Submit rating to Firestore with updated weighted calculation
  Future<void> _submitRating(double userRating) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
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
            // Add other necessary fields from uploads if needed
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

  /// Function to calculate user weight percentage based on vote count
  double _calculateUserWeightPercentage(int voteCount) {
    if (voteCount <= 0) {
      return 0.0;
    } else if (voteCount <= 100) {
      return (voteCount / 100) * 0.6;
    } else {
      return 0.6;
    }
  }

  /// Displays an information dialog
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Swipe Information',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Swipe from left to right to navigate between posts.',
          style: GoogleFonts.roboto(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!', style: GoogleFonts.roboto()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (allPosts.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Detailed Post',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          // Replaced Share icon with Information icon
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline, color: Colors.white),
              tooltip: 'Information',
              onPressed: () {
                _showInfoDialog();
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
        extendBodyBehindAppBar: true,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detailed Post',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // Replaced Share icon with Information icon
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            tooltip: 'Information',
            onPressed: () {
              _showInfoDialog();
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
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        controller: _pageController,
        itemCount: allPosts.length,
        onPageChanged: (index) {
          setState(() {
            currentPageIndex = index;
            var post = allPosts[index];
            _currentRating = double.tryParse(post['note'].toString()) ?? 0.0;
            _hasVoted = false; // Reset voting status
            _fetchChallengeCriteria(); // Fetch criteria for the new post
            _checkIfUserHasVoted(); // Recheck voting status for the new post
          });
        },
        itemBuilder: (context, index) {
          final post = allPosts[index];
          final imageUrl = post['imageURL'] as String? ?? '';
          final double rating = double.tryParse(post['note'].toString()) ?? 0.0;
          final String challengeId = post['challengeId'] as String? ?? 'default_challenge';
          final String uploadId = post.id;

          // Retrieve the rank from the widget parameter
          final int rank = widget.rank;

          return Stack(
            children: [
              // Main Image
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Center(
                    child: Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ),
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black54, Colors.transparent, Colors.black54],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Challenge Criteria and Rating
              Positioned(
                top: 100,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHALLENGE CRITERIA: $_criteria',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
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
                  ],
                ),
              ),
              // Rank Overlay
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    rank > 0 ? '#$rank' : '',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              // RightRatingButton for selecting the rating
              Positioned(
                bottom: 60,
                right: 16,
                child: RightRatingButton(
                  uploadId: uploadId,
                  currentRating: _currentRating,
                  onRatingSelected: _handleRatingSelected,
                  isSubmitting: _isSubmitting,
                  hasVoted: _hasVoted,
                ),
              ),
              // LeftActionButton for other actions (like, comment, participate)
              Positioned(
                bottom: 60,
                left: 16,
                child: LeftActionButton(
                  uploadId: uploadId,
                  onParticipate: _handleParticipate,
                  onRanking: _handleRanking,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
