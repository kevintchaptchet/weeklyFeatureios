// lib/screens/following_list.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weekly_features/WeeklyFeatures/Models/Users.dart'; // Correct import path
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../Views/profile.dart'; // Import the ProfileScreen

class FollowingList extends StatelessWidget {
  final String userId;

  FollowingList({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Following',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.purpleAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('following')
            .orderBy('followedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.purpleAccent,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Not following anyone yet',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            );
          }

          final following = snapshot.data!.docs.map((doc) {
            return doc['followingId'] as String;
          }).toList();

          return ListView.builder(
            itemCount: following.length,
            itemBuilder: (context, index) {
              final followingId = following[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(followingId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('Loading...'),
                    );
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Unknown User'),
                    );
                  }

                  final userData = userSnapshot.data!;
                  final user = UserModel.fromMap(
                      userData.data() as Map<String, dynamic>, userData.id);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.photoUrl != null
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? Icon(Icons.person, color: Colors.white)
                          : null,
                      backgroundColor: Colors.purpleAccent,
                    ),
                    title: Text(
                      user.username,
                      style: GoogleFonts.roboto(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      // Navigate to the following user's profile
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            userId: user.id, // Use 'userId' here
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
