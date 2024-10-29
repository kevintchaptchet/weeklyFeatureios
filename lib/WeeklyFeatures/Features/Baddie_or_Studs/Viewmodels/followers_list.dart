// lib/screens/followers_list.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weekly_features/WeeklyFeatures/Models/Users.dart'; // Import the UserModel
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../Views/profile.dart'; // Import the ProfileScreen

class FollowersList extends StatelessWidget {
  final String userId;

  FollowersList({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Followers',
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
            .collection('followers')
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
                'No followers yet',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            );
          }

          final followers = snapshot.data!.docs.map((doc) {
            return doc['followerId'] as String;
          }).toList();

          return ListView.builder(
            itemCount: followers.length,
            itemBuilder: (context, index) {
              final followerId = followers[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(followerId)
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
                      // Navigate to the follower's profile
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                              userId: user.id,
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
