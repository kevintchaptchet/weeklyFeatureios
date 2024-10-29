import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/bottomnavigation.dart';
import '../Models/ChallengeRankingPage.dart';
import '../Models/RightRatingButton.dart';
import '../Models/LeftActionButton.dart';
import '../Views/Participate.dart';
import '../Models/DetailedPostView.dart';
import 'package:google_fonts/google_fonts.dart';

class ChallengeVoteScreen extends ConsumerStatefulWidget {
  final String challengeId;

  const ChallengeVoteScreen({Key? key, required this.challengeId}) : super(key: key);

  @override
  ConsumerState<ChallengeVoteScreen> createState() => _ChallengeVoteScreenState();
}

class _ChallengeVoteScreenState extends ConsumerState<ChallengeVoteScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vote on Challenge',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
      body: SafeArea(
        child: ChallengeUploadsPageView(challengeId: widget.challengeId),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
      ),
    );
  }
}

class ChallengeUploadsPageView extends StatelessWidget {
  final String challengeId;

  const ChallengeUploadsPageView({Key? key, required this.challengeId}) : super(key: key);

  Stream<QuerySnapshot> _getChallengeImages() {
    return FirebaseFirestore.instance
        .collection('challenge')
        .doc(challengeId)
        .collection('images')
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getChallengeImages(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(child: Text("No images found for this challenge"));
        }

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final imageUrl = doc['imageURL'] as String? ?? '';
            final double rating = (doc['note'] is double)
                ? doc['note']
                : double.tryParse(doc['note'].toString()) ?? 0.0;
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
  final String uploadId;

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
  bool _isSubmitting = false;
  bool _hasVoted = false;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
    _checkIfUserHasVoted();
    _fetchChallengeCriteria();
  }

  Future<void> _fetchChallengeCriteria() async {
    try {
      DocumentSnapshot challengeDoc = await FirebaseFirestore.instance
          .collection('challenge')
          .doc(widget.challengeId)
          .get();

      if (challengeDoc.exists && mounted) {
        setState(() {
          _criteria = (challengeDoc['criteria'] ?? 'No Criteria Available').toUpperCase();
        });
      } else if (mounted) {
        setState(() {
          _criteria = 'CHALLENGE NOT FOUND';
        });
      }
    } catch (e) {
      developer.log('Error fetching challenge criteria: $e');
      if (mounted) {
        setState(() {
          _criteria = 'ERROR FETCHING CRITERIA';
        });
      }
    }
  }

  Future<void> _checkIfUserHasVoted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot voteDoc = await FirebaseFirestore.instance
          .collection('uploads')
          .doc(widget.uploadId)
          .collection('votes')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _hasVoted = voteDoc.exists;
        });
      }
    } catch (e) {
      developer.log('Error checking user vote: $e');
      if (mounted) {
        setState(() {
          _hasVoted = false;
        });
      }
    }
  }


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

  void _handleRatingSelected(double rating) async {
    if (_hasVoted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You have already voted on this image.')),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    developer.log('Rating selected: $rating');
    await _submitRating(rating);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _hasVoted = true;
      });
    }
  }

  Future<void> _submitRating(double userRating) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You must be logged in to vote.')),
        );
      }
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
        // Get upload document
        DocumentSnapshot uploadSnapshot = await transaction.get(uploadRef);
        if (!uploadSnapshot.exists) {
          throw Exception('Image does not exist.');
        }

        // Check if user has already voted
        DocumentSnapshot voteSnapshot = await transaction.get(voteRef);
        if (voteSnapshot.exists) {
          throw Exception('You have already voted on this image.');
        }

        // Retrieve existing values
        double originalNote = uploadSnapshot['note'] ?? 0.0;
        int voteCount = uploadSnapshot['voteCount'] ?? 0;
        double totalVoteValue = uploadSnapshot['totalVoteValue'] ?? 0.0;

        // Calculate new rating values
        double newTotalVoteValue = totalVoteValue + userRating;
        int newVoteCount = voteCount + 1;
        double newAverageUserRating = newTotalVoteValue / newVoteCount;
        double userWeightPercentage = _calculateUserWeightPercentage(newVoteCount);

        // Calculate new note value
        double newNote = (originalNote * 0.4 + newAverageUserRating * userWeightPercentage) /
            (0.4 + userWeightPercentage);

        // Ensure newNote is within valid range
        newNote = newNote.clamp(0.0, 10.0);

        // Update the upload document
        transaction.update(uploadRef, {
          'note': newNote,
          'voteCount': newVoteCount,
          'totalVoteValue': newTotalVoteValue,
        });

        // Update the challenge image document similarly
        transaction.update(challengeImageRef, {
          'note': newNote,
          'voteCount': newVoteCount,
          'totalVoteValue': newTotalVoteValue,
        });

        // Record the user's vote
        transaction.set(voteRef, {
          'userId': user.uid,
          'rating': userRating,
          'votedAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Your vote has been submitted!')),
        );
      }
    } catch (e) {
      developer.log('Error submitting rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting vote: ${e.toString()}')),
        );
      }
    }
  }


  Color _getRatingColor(double rating) {
    if (rating <= 5.0) {
      double green = (rating / 5.0) * 255;
      return Color.fromARGB(255, 255, green.toInt(), 0);
    } else {
      double red = ((10.0 - rating) / 5.0) * 255;
      return Color.fromARGB(255, red.toInt(), 255, 0);
    }
  }

  double _calculateUserWeightPercentage(int voteCount) {
    return (voteCount <= 100) ? (voteCount / 100) * 0.6 : 0.6;
  }

  @override
  Widget build(BuildContext context) {
    final double _padding = 16.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.network(
            widget.imageUrl,
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
        Positioned(
          top: _padding,
          left: _padding,
          right: _padding,
          child: Center(
            child: Text(
              'CHALLENGE CRITERIA: $_criteria',
              style: GoogleFonts.roboto(
                fontSize: 18,
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
          ),
        ),
        Positioned(
          bottom: _padding,
          left: _padding,
          right: _padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LeftActionButton(
                uploadId: widget.uploadId,
                onParticipate: _handleParticipate,
                onRanking: _handleRanking,
              ),
              Container(
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
              RightRatingButton(
                uploadId: widget.uploadId,
                currentRating: _currentRating,
                onRatingSelected: _handleRatingSelected,
                isSubmitting: _isSubmitting,
                hasVoted: _hasVoted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
