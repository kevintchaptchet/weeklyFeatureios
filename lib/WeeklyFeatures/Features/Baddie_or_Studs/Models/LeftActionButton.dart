// lib/WeeklyFeatures/Models/LeftActionButton.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/comments_modal.dart'; // Update the path accordingly
import 'package:weekly_features/WeeklyFeatures/Models/Users.dart'; // Import UserModel

class LeftActionButton extends StatefulWidget {
  final String uploadId;
  final VoidCallback onParticipate;
  final VoidCallback onRanking;

  const LeftActionButton({
    Key? key,
    required this.uploadId,
    required this.onParticipate,
    required this.onRanking,
  }) : super(key: key);

  @override
  _LeftActionButtonState createState() => _LeftActionButtonState();
}

class _LeftActionButtonState extends State<LeftActionButton>
    with SingleTickerProviderStateMixin {
  bool _isExpandedLeft = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool isLiking = false;
  bool showHeart = false;

  late CollectionReference _likesRef;
  late CollectionReference _commentsRef;

  bool hasUserLiked = false;

  UserModel? currentUser;

  StreamSubscription<DocumentSnapshot>? _uploadSubscription;

  int likeCount = 0;
  int commentCount = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _likesRef = FirebaseFirestore.instance
        .collection('uploads')
        .doc(widget.uploadId)
        .collection('likes');

    _commentsRef = FirebaseFirestore.instance
        .collection('uploads')
        .doc(widget.uploadId)
        .collection('comments');

    // Fetch current user model
    _fetchCurrentUser();

    // Listen to like and comment counts
    _uploadSubscription = FirebaseFirestore.instance
        .collection('uploads')
        .doc(widget.uploadId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          likeCount = snapshot.get('likes') ?? 0;
          commentCount = snapshot.get('commentCount') ?? 0;
        });
      }
    });

    // Listen to user's like status
    _checkIfUserLiked();
  }

  Future<void> _fetchCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle unauthenticated user if necessary
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          currentUser =
              UserModel.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);
        });
      }
    } catch (e) {
      developer.log('Error fetching user model: $e');
      if (mounted) {
        setState(() {
          // Handle error state if necessary
        });
      }
    }
  }

  Future<void> _checkIfUserLiked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot likeDoc = await _likesRef.doc(user.uid).get();
      if (mounted) {
        setState(() {
          hasUserLiked = likeDoc.exists;
        });
      }
    } catch (e) {
      developer.log('Error checking if user liked: $e');
      if (mounted) {
        setState(() {
          // Handle error state if necessary
        });
      }
    }
  }

  void _toggleExpansionLeft() {
    if (!mounted) return;
    setState(() {
      _isExpandedLeft = !_isExpandedLeft;
      if (_isExpandedLeft) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _handleLike() async {
    if (isLiking || currentUser == null) return;

    if (!mounted) return;

    setState(() {
      isLiking = true;
      if (!hasUserLiked) {
        showHeart = true;
      }
    });

    _animationController.forward();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Optionally, prompt user to log in
        return;
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference uploadRef =
        FirebaseFirestore.instance.collection('uploads').doc(widget.uploadId);
        DocumentReference likeRef = _likesRef.doc(user.uid);

        DocumentSnapshot uploadSnapshot = await transaction.get(uploadRef);
        if (!uploadSnapshot.exists) {
          throw Exception("Upload does not exist!");
        }

        int currentLikes = uploadSnapshot.get('likes') ?? 0;

        DocumentSnapshot likeSnapshot = await transaction.get(likeRef);
        if (!likeSnapshot.exists) {
          // User is liking the post
          transaction.set(likeRef, {'likedAt': FieldValue.serverTimestamp()});
          transaction.update(uploadRef, {'likes': currentLikes + 1});
          if (mounted) {
            setState(() {
              hasUserLiked = true;
            });
          }

          // Add a notification to the upload owner's notifications collection
          String ownerId = uploadSnapshot['userId'];
          String currentUsername = currentUser?.username ?? 'Someone';
          String message = '$currentUsername liked your picture.';

          await FirebaseFirestore.instance
              .collection('users')
              .doc(ownerId)
              .collection('notifications')
              .add({
            'type': 'like',
            'message': message,
            'senderId': user.uid,
            'senderUsername': currentUsername,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });
        } else {
          // User is unliking the post
          transaction.delete(likeRef);
          int newLikes = currentLikes > 0 ? currentLikes - 1 : 0;
          transaction.update(uploadRef, {'likes': newLikes});
          if (mounted) {
            setState(() {
              hasUserLiked = false;
            });
          }
        }
      });
    } catch (e) {
      developer.log('Error handling like: $e');
    } finally {
      if (!mounted) return;
      _animationController.reverse();
      // Hide the heart after a short delay
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            showHeart = false;
            isLiking = false;
          });
        }
      });
    }
  }

  void _openComments() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CommentsModal(uploadId: widget.uploadId),
    );
  }

  void _openVoteDistribution() async {
    try {
      // Fetch vote distribution data
      QuerySnapshot votesSnapshot = await FirebaseFirestore.instance
          .collection('uploads')
          .doc(widget.uploadId)
          .collection('votes')
          .get();

      // Fetch the original note
      DocumentSnapshot uploadSnapshot = await FirebaseFirestore.instance
          .collection('uploads')
          .doc(widget.uploadId)
          .get();

      String originalNote = uploadSnapshot.exists
          ? (uploadSnapshot['originalNote']?.toString() ?? 'No Note Available')
          : 'No Note Available';

      Map<int, int> distribution = {};

      for (int i = 1; i <= 10; i++) {
        distribution[i] = 0;
      }

      for (var doc in votesSnapshot.docs) {
        int rating = doc['rating']?.toInt() ?? 0;
        if (rating >= 1 && rating <= 10) {
          distribution[rating] = distribution[rating]! + 1;
        }
      }

      // Calculate total votes
      int totalVotes = distribution.values.fold(0, (a, b) => a + b);

      // Show vote distribution in a dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Row(
              children: [
                Text('Vote Distribution'),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.info_outline),
                  onPressed: () {
                    _showCalculationInfo();
                  },
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Original Note: $originalNote',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                totalVotes == 0
                    ? Text('No votes yet.')
                    : Container(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      int rating = index + 1;
                      int count = distribution[rating] ?? 0;
                      double percentage = totalVotes > 0
                          ? (count / totalVotes) * 100
                          : 0.0;
                      return Row(
                        children: [
                          Text(
                            '$rating:',
                            style: TextStyle(color: Colors.black),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  _getRatingColor(rating.toDouble())),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            '${count} (${percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Close'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    } catch (e) {
      developer.log('Error fetching vote distribution: $e');
      // Optionally, handle the error without showing a SnackBar
    }
  }

  void _showCalculationInfo() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Calculation Explanation"),
          content: SingleChildScrollView(
            child: Text(
              "The overall rating is calculated based on the original note and user votes. "
                  "Here's how it works:\n\n"
                  "1. **Original Note** contributes 40% to the overall rating.\n"
                  "2. **User Votes** contribute up to 60%, scaling with the number of votes.\n"
                  "   - Each vote adds to the total vote value and increments the vote count.\n"
                  "   - The average user rating is calculated from all votes.\n"
                  "   - The user weight percentage scales linearly from 0% to 60% as the vote count increases from 1 to 100.\n\n"
                  "3. The final overall rating is a weighted average of the original note and the average user rating based on the user weight percentage.",
              style: TextStyle(fontSize: 16),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Got it'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required int count,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      splashColor: color.withAlpha(50),
      child: Column(
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            '$count',
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Add the _getRatingColor method here
  Color _getRatingColor(double rating) {
    if (rating <= 5.0) {
      double green = (rating / 5.0) * 255;
      return Color.fromARGB(255, 255, green.toInt(), 0);
    } else {
      double red = ((10.0 - rating) / 5.0) * 255;
      return Color.fromARGB(255, red.toInt(), 255, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double _padding = 16.0;

    return Positioned(
      bottom: _padding,
      left: _padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_isExpandedLeft)
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withOpacity(0.5),
              ),
              child: Column(
                children: [
                  // Comment Button
                  _buildActionButton(
                    icon: Icons.comment,
                    label: 'Comment',
                    color: Colors.blueAccent,
                    onPressed: _openComments,
                    count: commentCount,
                  ),
                  SizedBox(height: 12),
                  // Like Button with Heart Animation
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildActionButton(
                        icon: hasUserLiked ? Icons.favorite : Icons.favorite_border,
                        label: 'Like',
                        color: hasUserLiked ? Colors.redAccent : Colors.grey,
                        onPressed: isLiking ? () {} : _handleLike,
                        count: likeCount,
                      ),
                      if (showHeart)
                        Positioned(
                          child: Icon(
                            Icons.favorite,
                            color: Colors.red.withOpacity(0.7),
                            size: 50,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Participate Button
                  _buildActionButton(
                    icon: Icons.person_add,
                    label: 'Participate',
                    color: Colors.orangeAccent,
                    onPressed: widget.onParticipate,
                    count: 0,
                  ),
                  SizedBox(height: 12),
                  // Ranking Button
                  _buildActionButton(
                    icon: Icons.leaderboard,
                    label: 'Ranking',
                    color: Colors.purpleAccent,
                    onPressed: widget.onRanking,
                    count: 0,
                  ),
                  SizedBox(height: 12),
                  // Vote Distribution Button
                  _buildActionButton(
                    icon: Icons.bar_chart,
                    label: 'Votes',
                    color: Colors.tealAccent,
                    onPressed: _openVoteDistribution,
                    count: 0,
                  ),
                ],
              ),
            ),
          SizedBox(height: 10),
          // Main Action Button (Menu)
          GestureDetector(
            onTap: _toggleExpansionLeft,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _isExpandedLeft ? Colors.grey : Colors.purpleAccent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _isExpandedLeft
                        ? Colors.grey.withOpacity(0.5)
                        : Colors.pinkAccent.withOpacity(0.5),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _isExpandedLeft ? Icons.close : Icons.menu,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _uploadSubscription?.cancel();
    super.dispose();
  }
}
