// lib/search_delegate.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/challenges.dart'; // Adjust the import paths as necessary
import 'package:weekly_features/WeeklyFeatures/Models/Users.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../Views/Participate.dart';
import '../Views/profile.dart';
import '../Views/search.dart'; // Import ChallengeBox and ChallengeDetailModal

class CustomSearchDelegate extends SearchDelegate {
  // Fetch all users and challenges once to reduce the number of reads
  Future<List<UserModel>> _fetchAllUsers() async {
    QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection('users').get();
    return snapshot.docs.map((doc) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  Future<List<Challenge>> _fetchAllChallenges() async {
    QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection('challenge').get();
    return snapshot.docs.map((doc) {
      return Challenge.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  // Combine both users and challenges
  Future<List<dynamic>> _fetchAllData() async {
    final users = await _fetchAllUsers();
    final challenges = await _fetchAllChallenges();
    return [users, challenges];
  }

  // Helper method for case-insensitive substring matching
  bool _matches(String source, String query) {
    return source.toLowerCase().contains(query.toLowerCase());
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Text(
          'Search for users or challenges',
          style: GoogleFonts.roboto(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      );
    }

    return FutureBuilder(
      future: _fetchAllData(),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
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

        final users = snapshot.data![0] as List<UserModel>;
        final challenges = snapshot.data![1] as List<Challenge>;

        // Perform client-side filtering
        final filteredUsers =
        users.where((user) => _matches(user.username, query)).toList();
        final filteredChallenges =
        challenges.where((challenge) => _matches(challenge.criteria, query)).toList();

        if (filteredUsers.isEmpty && filteredChallenges.isEmpty) {
          return Center(
            child: Text(
              'No results found',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return ListView(
          children: [
            if (filteredUsers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Users',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ...filteredUsers.map((user) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Icon(Icons.person, color: Colors.white)
                      : null,
                  backgroundColor: Colors.blueAccent,
                ),
                title: Text(
                  user.username,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  close(context, null);
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
            }).toList(),
            if (filteredChallenges.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Challenges',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ...filteredChallenges.map((challenge) {
              return ChallengeBox(
                key: ValueKey(challenge.id),
                challenge: challenge,
              );
            }).toList(),
          ],
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Display results similarly to buildSuggestions
    if (query.isEmpty) {
      return Center(
        child: Text(
          'Enter a keyword to search',
          style: GoogleFonts.roboto(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      );
    }

    return FutureBuilder(
      future: _fetchAllData(),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
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

        final users = snapshot.data![0] as List<UserModel>;
        final challenges = snapshot.data![1] as List<Challenge>;

        // Perform client-side filtering
        final filteredUsers =
        users.where((user) => _matches(user.username, query)).toList();
        final filteredChallenges =
        challenges.where((challenge) => _matches(challenge.criteria, query)).toList();

        if (filteredUsers.isEmpty && filteredChallenges.isEmpty) {
          return Center(
            child: Text(
              'No results found',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return ListView(
          children: [
            if (filteredUsers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Users',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ...filteredUsers.map((user) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Icon(Icons.person, color: Colors.white)
                      : null,
                  backgroundColor: Colors.blueAccent,
                ),
                title: Text(
                  user.username,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  close(context, null);
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
            }).toList(),
            if (filteredChallenges.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Challenges',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ...filteredChallenges.map((challenge) {
              return ChallengeBox(
                key: ValueKey(challenge.id),
                challenge: challenge,
              );
            }).toList(),
          ],
        );
      },
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      primaryColor: Colors.blueAccent,
      textTheme: GoogleFonts.robotoTextTheme(
        theme.textTheme,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: GoogleFonts.roboto(
          color: Colors.white54,
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        close(context, null);
      },
    );
  }
}
