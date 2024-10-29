// lib/screens/NotificationsScreen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of notifications for the current user
  Stream<QuerySnapshot> _notificationsStream() {
    return _firestore
        .collection('users')
        .doc(currentUser?.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Marks a notification as read
  Future<void> _markAsRead(String notificationId) async {
    await _firestore
        .collection('users')
        .doc(currentUser?.uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Text(
                'No notifications yet',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;

              return ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: data['read'] ? Colors.grey : Colors.blueAccent,
                ),
                title: Text(
                  data['message'] ?? '',
                  style: GoogleFonts.roboto(
                    fontWeight:
                    data['read'] ? FontWeight.normal : FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                subtitle: Text(
                  (data['timestamp'] as Timestamp?)?.toDate().toString() ??
                      '',
                  style: GoogleFonts.roboto(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  _markAsRead(notification.id);
                  // Optionally, navigate to a relevant screen based on notification type
                },
              );
            },
          );
        },
      ),
    );
  }
}
