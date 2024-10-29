// lib/services/follow_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A service that manages follow and unfollow actions between users.
class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// The currently authenticated user.
  User? get currentUser => _auth.currentUser;

  /// Follows a user with the given [targetUserId].
  ///
  /// Throws an [Exception] if:
  /// - The user is not authenticated.
  /// - The user attempts to follow themselves.
  /// - The target user does not exist.
  /// - Firestore operations fail.
  Future<void> followUser(String targetUserId) async {
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    String currentUserId = currentUser!.uid;

    // Prevent users from following themselves.
    if (currentUserId == targetUserId) {
      throw Exception('You cannot follow yourself');
    }

    DocumentReference targetUserRef =
    _firestore.collection('users').doc(targetUserId);

    // Check if the target user exists.
    DocumentSnapshot targetUserSnapshot = await targetUserRef.get();
    if (!targetUserSnapshot.exists) {
      throw Exception('Target user does not exist');
    }

    WriteBatch batch = _firestore.batch();

    // References to the current user's following subcollection and target user's followers subcollection.
    DocumentReference currentUserFollowingRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId);

    DocumentReference targetUserFollowersRef = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId);

    // Data to add to the following and followers subcollections.
    Map<String, dynamic> followingData = {
      'followingId': targetUserId,
      'followedAt': FieldValue.serverTimestamp(),
    };

    Map<String, dynamic> followersData = {
      'followerId': currentUserId,
      'followedAt': FieldValue.serverTimestamp(),
    };

    // Add the follow entries to both subcollections.
    batch.set(currentUserFollowingRef, followingData);
    batch.set(targetUserFollowersRef, followersData);

    try {
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  /// Unfollows a user with the given [targetUserId].
  ///
  /// Throws an [Exception] if:
  /// - The user is not authenticated.
  /// - Firestore operations fail.
  Future<void> unfollowUser(String targetUserId) async {
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    String currentUserId = currentUser!.uid;

    WriteBatch batch = _firestore.batch();

    // References to the current user's following subcollection and target user's followers subcollection.
    DocumentReference currentUserFollowingRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId);

    DocumentReference targetUserFollowersRef = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId);

    // Remove the follow entries from both subcollections.
    batch.delete(currentUserFollowingRef);
    batch.delete(targetUserFollowersRef);

    try {
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }

  /// Checks if the current user is following the user with [targetUserId].
  ///
  /// Returns `true` if following, `false` otherwise.
  ///
  /// Throws an [Exception] if the user is not authenticated or Firestore operations fail.
  Future<bool> isFollowing(String targetUserId) async {
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    String currentUserId = currentUser!.uid;

    DocumentReference followingRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId);

    try {
      DocumentSnapshot docSnapshot = await followingRef.get();
      return docSnapshot.exists;
    } catch (e) {
      throw Exception('Failed to check following status: $e');
    }
  }
}
