// comments_modal.dart

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:weekly_features/WeeklyFeatures/Models/Users.dart'; // Import UserModel
import 'package:google_fonts/google_fonts.dart';

class CommentsModal extends StatefulWidget {
  final String uploadId;

  CommentsModal({required this.uploadId});

  @override
  _CommentsModalState createState() => _CommentsModalState();
}

class _CommentsModalState extends State<CommentsModal> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();

  late CollectionReference _commentsRef;

  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    _commentsRef = FirebaseFirestore.instance
        .collection('uploads')
        .doc(widget.uploadId)
        .collection('comments');
    _fetchCurrentUser();
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

      if (userDoc.exists) {
        setState(() {
          currentUser =
              UserModel.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);
        });
      }
    } catch (e) {
      developer.log('Error fetching user model: $e');
    }
  }

  // Helper method to send notifications
  Future<void> _sendNotification({
    required String recipientUserId,
    required String type, // e.g., 'comment', 'reply', 'like'
    required String message,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientUserId)
          .collection('notifications')
          .add({
        'type': type,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        // Add any other fields as needed, e.g., senderUserId, uploadId, etc.
      });
    } catch (e) {
      developer.log('Error sending notification: $e');
    }
  }

  // Helper method to get owner ID of the upload
  Future<String?> _getUploadOwnerId() async {
    try {
      DocumentSnapshot uploadDoc = await FirebaseFirestore.instance
          .collection('uploads')
          .doc(widget.uploadId)
          .get();
      if (uploadDoc.exists) {
        return uploadDoc.get('ownerId') as String?;
      }
    } catch (e) {
      developer.log('Error fetching upload owner ID: $e');
    }
    return null;
  }

  // Helper method to get owner ID of a comment
  Future<String?> _getCommentOwnerId(String commentId) async {
    try {
      DocumentSnapshot commentDoc = await _commentsRef.doc(commentId).get();
      if (commentDoc.exists) {
        return commentDoc.get('userId') as String?;
      }
    } catch (e) {
      developer.log('Error fetching comment owner ID: $e');
    }
    return null;
  }

  // Helper method to get owner ID of a reply
  Future<String?> _getReplyOwnerId(String commentId, String replyId) async {
    try {
      DocumentSnapshot replyDoc = await _commentsRef
          .doc(commentId)
          .collection('replies')
          .doc(replyId)
          .get();
      if (replyDoc.exists) {
        return replyDoc.get('userId') as String?;
      }
    } catch (e) {
      developer.log('Error fetching reply owner ID: $e');
    }
    return null;
  }

  Future<void> _addComment(String text) async {
    if (text.trim().isEmpty || currentUser == null) return;

    try {
      // Add the comment
      DocumentReference commentRef = await _commentsRef.add({
        'text': text.trim(),
        'commentedAt': FieldValue.serverTimestamp(),
        'userId': currentUser!.id,
        'username': currentUser!.username,
        'photoUrl': currentUser!.photoUrl ?? '',
        'likesCount': 0,
      });

      // Update comment count
      await FirebaseFirestore.instance
          .collection('uploads')
          .doc(widget.uploadId)
          .update({'commentCount': FieldValue.increment(1)});

      // Fetch the owner of the upload to notify
      String? uploadOwnerId = await _getUploadOwnerId();
      if (uploadOwnerId != null && uploadOwnerId != currentUser!.id) {
        await _sendNotification(
          recipientUserId: uploadOwnerId,
          type: 'comment',
          message: '${currentUser!.username} commented on your upload.',
        );
      }
    } catch (e) {
      developer.log('Error adding comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment.')),
      );
    }
  }

  Future<void> _addReply(String commentId, String text) async {
    if (text.trim().isEmpty || currentUser == null) return;

    try {
      // Add the reply
      DocumentReference replyRef = await _commentsRef
          .doc(commentId)
          .collection('replies')
          .add({
        'text': text.trim(),
        'repliedAt': FieldValue.serverTimestamp(),
        'userId': currentUser!.id,
        'username': currentUser!.username,
        'photoUrl': currentUser!.photoUrl ?? '',
        'likesCount': 0,
      });

      // Fetch the owner of the comment to notify
      String? commentOwnerId = await _getCommentOwnerId(commentId);
      if (commentOwnerId != null && commentOwnerId != currentUser!.id) {
        await _sendNotification(
          recipientUserId: commentOwnerId,
          type: 'reply',
          message: '${currentUser!.username} replied to your comment.',
        );
      }
    } catch (e) {
      developer.log('Error adding reply: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add reply.')),
      );
    }
  }

  Future<void> _toggleLikeComment(String commentId, bool isLiked) async {
    if (currentUser == null) return;

    DocumentReference likeRef = _commentsRef
        .doc(commentId)
        .collection('likes')
        .doc(currentUser!.id);

    try {
      if (!isLiked) {
        // Like the comment
        await likeRef.set({
          'likedAt': FieldValue.serverTimestamp(),
        });
        await _commentsRef.doc(commentId).update({
          'likesCount': FieldValue.increment(1),
        });

        // Fetch the owner of the comment to notify
        String? commentOwnerId = await _getCommentOwnerId(commentId);
        if (commentOwnerId != null && commentOwnerId != currentUser!.id) {
          await _sendNotification(
            recipientUserId: commentOwnerId,
            type: 'like',
            message: '${currentUser!.username} liked your comment.',
          );
        }
      } else {
        // Unlike the comment
        await likeRef.delete();
        await _commentsRef.doc(commentId).update({
          'likesCount': FieldValue.increment(-1),
        });
        // Optionally, remove a notification if you implemented that logic
      }
    } catch (e) {
      developer.log('Error toggling like on comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle like on comment.')),
      );
    }
  }

  // Method to check if the user liked a comment
  Future<bool> _checkIfUserLikedComment(String commentId) async {
    if (currentUser == null) return false;

    try {
      DocumentSnapshot likeDoc = await _commentsRef
          .doc(commentId)
          .collection('likes')
          .doc(currentUser!.id)
          .get();
      return likeDoc.exists;
    } catch (e) {
      developer.log('Error checking like status on comment: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _commentsRef
                      .orderBy('commentedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No comments yet.'));
                    }

                    return ListView(
                      controller: scrollController,
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final commentId = doc.id;
                        final text = data['text'] ?? '';
                        final username = data['username'] ?? 'Anonymous';
                        final photoUrl = data['photoUrl'] ?? '';
                        final likesCount = data['likesCount'] ?? 0;

                        return FutureBuilder<bool>(
                          future: _checkIfUserLikedComment(commentId),
                          builder: (context, likeSnapshot) {
                            bool isLiked = likeSnapshot.data ?? false;

                            return CommentTile(
                              uploadId: widget.uploadId, // Pass uploadId
                              commentId: commentId,
                              text: text,
                              username: username,
                              photoUrl: photoUrl,
                              likesCount: likesCount,
                              isLiked: isLiked,
                              onLike: () {
                                _toggleLikeComment(commentId, isLiked);
                              },
                              onReply: (replyText) {
                                _addReply(commentId, replyText);
                              },
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        _addComment(value);
                        _commentController.clear();
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: () {
                      _addComment(_commentController.text);
                      _commentController.clear();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    super.dispose();
  }
}

class CommentTile extends StatefulWidget {
  final String uploadId; // Add uploadId
  final String commentId;
  final String text;
  final String username;
  final String photoUrl;
  final int likesCount;
  final bool isLiked;
  final VoidCallback onLike;
  final Function(String) onReply;

  CommentTile({
    required this.uploadId, // Add uploadId
    required this.commentId,
    required this.text,
    required this.username,
    required this.photoUrl,
    required this.likesCount,
    required this.isLiked,
    required this.onLike,
    required this.onReply,
  });

  @override
  _CommentTileState createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool _isReplying = false;
  final TextEditingController _replyController = TextEditingController();

  void _submitReply() {
    String replyText = _replyController.text.trim();
    if (replyText.isNotEmpty) {
      widget.onReply(replyText);
      setState(() {
        _isReplying = false;
      });
      _replyController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage:
                widget.photoUrl.isNotEmpty ? NetworkImage(widget.photoUrl) : null,
                child: widget.photoUrl.isEmpty
                    ? Icon(Icons.person, color: Colors.white)
                    : null,
                backgroundColor: Colors.blueAccent,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.username,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(widget.text),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  widget.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: widget.isLiked ? Colors.red : Colors.grey,
                  size: 20,
                ),
                onPressed: widget.onLike,
              ),
              Text('${widget.likesCount}'), // ✅ Corrected
              SizedBox(width: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isReplying = !_isReplying;
                  });
                },
                child: Text('Reply'),
              ),
            ],
          ),
          if (_isReplying)
            Padding(
              padding: const EdgeInsets.only(left: 40.0, bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: InputDecoration(
                        hintText: 'Write a reply...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) => _submitReply(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: _submitReply,
                  ),
                ],
              ),
            ),
          // Display replies if any
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('uploads')
                .doc(widget.uploadId) // Corrected to use uploadId
                .collection('comments')
                .doc(widget.commentId)
                .collection('replies')
                .orderBy('repliedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(left: 40.0),
                child: Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final replyId = doc.id;
                    final replyText = data['text'] ?? '';
                    final replyUsername = data['username'] ?? 'Anonymous';
                    final replyPhotoUrl = data['photoUrl'] ?? '';
                    final replyLikesCount = data['likesCount'] ?? 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundImage: replyPhotoUrl.isNotEmpty
                                ? NetworkImage(replyPhotoUrl)
                                : null,
                            child: replyPhotoUrl.isEmpty
                                ? Icon(Icons.person, color: Colors.white)
                                : null,
                            backgroundColor: Colors.blueAccent,
                            radius: 12,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  replyUsername,
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  replyText,
                                  style: TextStyle(fontSize: 12),
                                ),
                                Row(
                                  children: [
                                    LikeButton(
                                      uploadId: widget.uploadId, // Pass uploadId
                                      commentId: widget.commentId,
                                      replyId: replyId,
                                    ),
                                    SizedBox(width: 8),
                                    // Add more actions if needed
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class LikeButton extends StatefulWidget {
  final String uploadId; // Add uploadId
  final String commentId;
  final String replyId;

  LikeButton({required this.uploadId, required this.commentId, required this.replyId});

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool isLiked = false;
  int likesCount = 0;

  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _fetchLikeStatus();
    _fetchLikesCount();
  }

  Future<void> _fetchCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          currentUser =
              UserModel.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);
        });
      }
    } catch (e) {
      developer.log('Error fetching current user: $e');
    }
  }

  Future<void> _fetchLikeStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot likeDoc = await FirebaseFirestore.instance
          .collection('uploads')
          .doc(widget.uploadId)
          .collection('comments')
          .doc(widget.commentId)
          .collection('replies')
          .doc(widget.replyId)
          .collection('likes')
          .doc(user.uid)
          .get();

      setState(() {
        isLiked = likeDoc.exists;
      });
    } catch (e) {
      developer.log('Error fetching like status on reply: $e');
    }
  }

  Future<void> _fetchLikesCount() async {
    try {
      QuerySnapshot likesSnapshot = await FirebaseFirestore.instance
          .collection('uploads')
          .doc(widget.uploadId)
          .collection('comments')
          .doc(widget.commentId)
          .collection('replies')
          .doc(widget.replyId)
          .collection('likes')
          .get();

      setState(() {
        likesCount = likesSnapshot.docs.length;
      });
    } catch (e) {
      developer.log('Error fetching likes count on reply: $e');
    }
  }

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || currentUser == null) return;

    DocumentReference likeRef = FirebaseFirestore.instance
        .collection('uploads')
        .doc(widget.uploadId)
        .collection('comments')
        .doc(widget.commentId)
        .collection('replies')
        .doc(widget.replyId)
        .collection('likes')
        .doc(user.uid);

    try {
      if (!isLiked) {
        await likeRef.set({
          'likedAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          isLiked = true;
          likesCount += 1;
        });

        // Fetch the owner of the reply to notify
        String? replyOwnerId = await _getReplyOwnerId(widget.commentId, widget.replyId);
        if (replyOwnerId != null && replyOwnerId != currentUser!.id) {
          await _sendNotification(
            recipientUserId: replyOwnerId,
            type: 'like',
            message: '${currentUser!.username} liked your reply.',
          );
        }
      } else {
        await likeRef.delete();
        setState(() {
          isLiked = false;
          likesCount -= 1;
        });
        // Optionally, remove a notification if you implemented that logic
      }
    } catch (e) {
      developer.log('Error toggling like on reply: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle like on reply.')),
      );
    }
  }

  // Helper method to get owner ID of a reply
  Future<String?> _getReplyOwnerId(String commentId, String replyId) async {
    try {
      DocumentSnapshot replyDoc = await FirebaseFirestore.instance
          .collection('uploads')
          .doc(widget.uploadId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .doc(replyId)
          .get();
      if (replyDoc.exists) {
        return replyDoc.get('userId') as String?;
      }
    } catch (e) {
      developer.log('Error fetching reply owner ID: $e');
    }
    return null;
  }

  // Helper method to send notifications
  Future<void> _sendNotification({
    required String recipientUserId,
    required String type,
    required String message,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientUserId)
          .collection('notifications')
          .add({
        'type': type,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        // Add any other fields as needed, e.g., senderUserId, uploadId, etc.
      });
    } catch (e) {
      developer.log('Error sending notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : Colors.grey,
            size: 16,
          ),
          onPressed: _toggleLike,
        ),
        Text('$likesCount'),
      ],
    );
  }
}
