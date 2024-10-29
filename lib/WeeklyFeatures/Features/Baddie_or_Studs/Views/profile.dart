// lib/screens/ProfileScreen.dart

import 'dart:developer' as developer;
import 'dart:io'; // For File operations
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../Views/NotificationScreen.dart'; // For image picking

// Import necessary widgets and models
import '../Models/challenges.dart';
import '../Views/search.dart'; // Import the Challenge model
import '../Models/bottomnavigation.dart'; // Import the BottomNavigation widget
import '../Views/Participate.dart';
import '../Models/ChallengeRankingPage.dart'; // For custom fonts
import '../Viewmodels/follow_service.dart'; // Import the FollowService
import '../Viewmodels/followers_list.dart'; // Import FollowersList screen
import '../Viewmodels/following_list.dart'; // Import FollowingList screen
import '../Models/search_delegate.dart'; // Import the CustomSearchDelegate
import '../Models/stripe_payment.dart';
import '../Views/settings.dart'; // Import the SettingsScreen
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage
import '../Models/RightRatingButton.dart'; // Import RightRatingButton
import '../Models/LeftActionButton.dart'; // Import LeftActionButton
import '../Views/Baddie_or_studs_dashboard.dart'; // Import the UploadPage
import '../Models/DetailedPostView.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  ProfileScreen({this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // User Information
  User? currentUser;
  String? username;
  String? photoUrl;
  String? bio; // Optional bio field
  int _uploadsLeft = 0;

  // Followers and Following Counts
  int followersCount = 0;
  int followingCount = 0;

  // Follow Status
  bool _isFollowing = false;
  bool _isLoadingFollow = true;

  // Loading States
  bool _loading = true;

  // Stripe Payment Service
  final StripePaymentService _stripePaymentService = StripePaymentService();

  // Tab Controller
  late TabController _tabController;

  // User Posts
  List<DocumentSnapshot> userPosts = [];

  // Challenges Participating
  List<Challenge> participatingChallenges = [];

  // Challenges Created
  List<DocumentSnapshot> createdChallenges = [];

  // Post Rank Map
  Map<String, Map<String, int>> postRankMap = {};

  // Image Picker
  final ImagePicker _picker = ImagePicker();

  // Follow Service
  final FollowService _followService = FollowService();

  // Define targetUserId
  late String targetUserId;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _tabController = TabController(length: 3, vsync: this);
    targetUserId = widget.userId ?? currentUser?.uid ?? '';

    _fetchUserData();
    _fetchFollowersCount();
    _fetchFollowingCount();

    if (widget.userId != null) {
      _checkFollowingStatus();
    } else {
      setState(() {
        _isLoadingFollow = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Fetches user data based on targetUserId
  Future<void> _fetchUserData() async {
    if (targetUserId.isNotEmpty) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .get();

      if (userDoc.exists) {
        setState(() {
          username = userDoc['username'] ?? 'Unnamed User';
          photoUrl = userDoc['photoUrl'];
          bio = userDoc['bio'] ?? '';
          _uploadsLeft = userDoc['ul'] ?? 0; // Fetch the UL count here
        });
      } else {
        setState(() {
          username = 'User not found';
          photoUrl = null;
          bio = '';
          _uploadsLeft = 0; // Default to 0 if the user is not found
        });
      }
    }
  }

  /// Fetches followers count
  Future<void> _fetchFollowersCount() async {
    if (targetUserId.isNotEmpty) {
      QuerySnapshot followersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .get();

      setState(() {
        followersCount = followersSnapshot.size;
      });
    }
  }

  /// Fetches following count
  Future<void> _fetchFollowingCount() async {
    if (targetUserId.isNotEmpty) {
      QuerySnapshot followingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('following')
          .get();

      setState(() {
        followingCount = followingSnapshot.size;
      });
    }
  }

  /// Checks if the current user is following the target user
  Future<void> _checkFollowingStatus() async {
    if (currentUser != null && widget.userId != null) {
      bool isFollowing = await _followService.isFollowing(targetUserId);
      setState(() {
        _isFollowing = isFollowing;
        _isLoadingFollow = false;
      });
    } else {
      setState(() {
        _isLoadingFollow = false;
      });
    }
  }

  /// Toggles follow/unfollow status
  void _toggleFollow() async {
    setState(() {
      _isLoadingFollow = true;
    });

    try {
      if (_isFollowing) {
        await _followService.unfollowUser(targetUserId);
        setState(() {
          _isFollowing = false;
          followersCount = followersCount > 0 ? followersCount - 1 : 0;
        });
      } else {
        await _followService.followUser(targetUserId);
        setState(() {
          _isFollowing = true;
          followersCount += 1;
        });

        // Add a notification to the target user
        await _addFollowNotification(targetUserId);
      }
    } catch (e) {
      _showErrorDialog('Error', 'Failed to update follow status: ${e.toString()}');
    } finally {
      setState(() {
        _isLoadingFollow = false;
      });
    }
  }

  /// Adds a follow notification to the target user's notifications
  Future<void> _addFollowNotification(String targetUserId) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    final String currentUsername = username ?? 'Someone';
    final String message = '$currentUsername started following you.';

    // Add notification to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId)
        .collection('notifications')
        .add({
      'type': 'follow',
      'message': message,
      'senderId': currentUser.uid,
      'senderUsername': currentUsername,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    // The Cloud Function will handle sending the push notification
  }

  /// Displays an error dialog with a title and message
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title,
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.roboto()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.roboto()),
          ),
        ],
      ),
    );
  }

  /// Displays a success dialog with a title and message
  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title,
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.roboto()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.roboto()),
          ),
        ],
      ),
    );
  }

  /// Builds the profile header
  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Profile Image with tap to edit
        GestureDetector(
          onTap: currentUser?.uid == targetUserId ? _editProfilePicture : null,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle, // No rounded edges
              color: Colors.white12,
              image: photoUrl != null
                  ? DecorationImage(
                image: CachedNetworkImageProvider(photoUrl!),
                fit: BoxFit.cover,
              )
                  : null,
              border: Border.all(
                color: Colors.white54,
                width: 2,
              ),
            ),
            child: photoUrl == null
                ? Icon(
              Icons.person,
              size: 60,
              color: Colors.white54,
            )
                : null,
          ),
        ),
        SizedBox(height: 12),
        // Username with pencil icon for editing
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              username ?? 'Anonymous',
              style: GoogleFonts.roboto(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            if (currentUser?.uid == targetUserId)
              GestureDetector(
                onTap: _editUsername,
                child: Icon(
                  Icons.edit,
                  color: Colors.white70,
                  size: 24,
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        // Bio with pencil icon for editing
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: currentUser?.uid == targetUserId ? _editBio : null,
                child: Text(
                  bio ?? '',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (currentUser?.uid == targetUserId && (bio?.isNotEmpty ?? false))
              GestureDetector(
                onTap: _editBio,
                child: Icon(
                  Icons.edit,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
          ],
        ),
        SizedBox(height: 16),
        if (widget.userId != null && widget.userId != currentUser?.uid)
          _buildFollowButton(),
        SizedBox(height: 16),

        // Redesigned UL and "+" button row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_file, // Upload icon
              color: Colors.white70,
              size: 24,
            ),
            SizedBox(width: 8), // Space between icon and text
            Text(
              'Uploads Left: $_uploadsLeft', // Display UL count
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(width: 8), // Space between text and button
            // "+" Button
            GestureDetector(
              onTap: () async {
                bool paymentSuccess =
                await _stripePaymentService.makePayment(context, targetUserId);

                if (paymentSuccess) {
                  // Fetch the current UL count
                  DocumentReference userRef = FirebaseFirestore.instance
                      .collection('users')
                      .doc(targetUserId);

                  DocumentSnapshot userSnapshot = await userRef.get();
                  if (userSnapshot.exists) {
                    int currentUL = userSnapshot['ul'] ?? 0;

                    // Add 10 uploads to the current UL value
                    int newUL = currentUL + 10;

                    // Update Firestore with the new UL value
                    await userRef.update({'ul': newUL});

                    // Show confirmation
                    _showSuccessDialog(
                        'Success', 'You now have 10 additional uploads.');

                    // Update UI to reflect the new UL count
                    setState(() {
                      _uploadsLeft = newUL;
                    });
                  }
                } else {
                  _showErrorDialog('Payment Failed', 'Please try again.');
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 16), // Add space before followers section

        // Followers and Following Counts with navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowersList(userId: targetUserId),
                  ),
                );
              },
              child: _buildCountCard('Followers', followersCount),
            ),
            SizedBox(width: 24),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowingList(userId: targetUserId),
                  ),
                );
              },
              child: _buildCountCard('Following', followingCount),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the follow/unfollow button
  Widget _buildFollowButton() {
    if (_isLoadingFollow) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          foregroundColor:
          _isFollowing ? Colors.redAccent : Colors.blueAccent,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: _toggleFollow,
      style: ElevatedButton.styleFrom(
        backgroundColor:
        _isFollowing ? Colors.redAccent : Colors.blueAccent,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Text(
        _isFollowing ? 'Unfollow' : 'Follow',
        style: GoogleFonts.roboto(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Builds the followers/following count card
  Widget _buildCountCard(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// Builds the participating challenges list
  Widget _buildParticipatingChallenges() {
    return Expanded(
      child: participatingChallenges.isEmpty
          ? Center(
        child: Text(
          'Not participating in any challenges yet',
          style: GoogleFonts.roboto(
            fontSize: 18,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(8.0),
        itemCount: participatingChallenges.length,
        itemBuilder: (context, index) {
          final challenge = participatingChallenges[index];

          return Container(
            margin: EdgeInsets.only(bottom: 16), // Space between each challenge
            decoration: BoxDecoration(
              color: Colors.purpleAccent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ChallengeBox(
                key: ValueKey(challenge.id),
                challenge: challenge,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the created challenges list
  Widget _buildCreatedChallenges() {
    return Expanded(
      child: createdChallenges.isEmpty
          ? Center(
        child: Text(
          'You have not created any challenges yet',
          style: GoogleFonts.roboto(
            fontSize: 18,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(8.0),
        itemCount: createdChallenges.length,
        itemBuilder: (context, index) {
          final challengeData = createdChallenges[index];
          final challenge = Challenge.fromMap(
              challengeData.data() as Map<String, dynamic>, challengeData.id);

          return Container(
            margin: EdgeInsets.only(bottom: 16), // Space between each challenge
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ChallengeBox(
                key: ValueKey(challenge.id),
                challenge: challenge,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the tabs
  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: Colors.white,
      tabs: [
        Tab(
          icon: Icon(Icons.grid_on),
          text: 'Posts',
        ),
        Tab(
          icon: Icon(Icons.group),
          text: 'Participating',
        ),
        Tab(
          icon: Icon(Icons.create),
          text: 'Created',
        ),
      ],
    );
  }
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
  void _showInformationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Information"),
          content: Text(
            "• 10 dollars means 10 uploads left.\n\n"
                "• Swipe left to right to navigate posts.\n\n"
                "• For feature requests, check 'Feature Request' in settings.",
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
  /// Builds user posts grid with lazy loading
  Widget _buildUserPosts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('uploads')
          .where('userId', isEqualTo: targetUserId)
          .orderBy('uploadedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading posts',
              style: GoogleFonts.roboto(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No posts yet',
              style: GoogleFonts.roboto(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          itemCount: docs.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Three posts per row
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 1, // Square tiles
          ),
          itemBuilder: (BuildContext context, int index) {
            final post = docs[index];
            final imageUrl = post['imageURL'] as String? ?? '';
            final double rating = double.tryParse(post['note'].toString()) ?? 0.0;
            final String challengeId = post['challengeId'] as String? ?? 'default_challenge';
            final String uploadId = post.id;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailedPostView(
                      imageUrl: imageUrl,
                      rating: rating,
                      challengeId: challengeId,
                      uploadId: uploadId,
                      initialIndex: index, // Pass the initial index
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white12,
                ),
                child: Stack(
                  children: [
                    // Image
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Rating Overlay
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getRatingColor(rating).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
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
                          '#${index + 1}',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the tab views
  Widget _buildTabViews() {
    return Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [
          // User Posts Tab
          _buildUserPosts(),

          // Challenges Participating Tab
          _buildParticipatingChallenges(),

          // Challenges Created Tab
          _buildCreatedChallenges(),
        ],
      ),
    );
  }

  /// Builds the search and settings icons in the AppBar
  Widget _buildAppBar(BuildContext context) {
    return  AppBar(
    leading: IconButton(
    icon: Icon(Icons.info_outline, color: Colors.white),
    tooltip: 'Information',
    onPressed: _showInformationDialog,
    ),
    title: Text(
    'Profile',
    style: GoogleFonts.roboto(
    fontWeight: FontWeight.w500,
    color: Colors.white,
    ),
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    actions: [
    IconButton(
    icon: Icon(Icons.settings, color: Colors.white), // Settings icon
    tooltip: 'Settings',
    onPressed: () {
    Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => SettingsScreen()),
    );
    },
    ),
    IconButton(
    icon: Icon(Icons.notifications, color: Colors.white), // Notification icon
    tooltip: 'Notifications',
    onPressed: () {
    Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => NotificationsScreen()),
    );
    },
    ),
    IconButton(
    icon: Icon(Icons.search, color: Colors.white),
    tooltip: 'Search',
    onPressed: () {
    showSearch(
    context: context,
    delegate: CustomSearchDelegate(),
    );
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
    );
  }

  /// Handles editing of profile picture
  Future<void> _editProfilePicture() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        String fileName =
            'profile_pictures/${targetUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Upload to Firebase Storage
        FirebaseStorage storage = FirebaseStorage.instance;
        Reference ref = storage.ref().child(fileName);
        UploadTask uploadTask = ref.putFile(imageFile);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Update Firestore
        await FirebaseFirestore.instance.collection('users').doc(targetUserId).update({
          'photoUrl': downloadUrl,
        });

        setState(() {
          photoUrl = downloadUrl;
        });

        _showSuccessDialog('Success', 'Profile picture updated successfully!');
      }
    } catch (e) {
      developer.log('Error updating profile picture: $e');
      _showErrorDialog(
          'Error', 'Failed to update profile picture. Please try again.');
    }
  }

  /// Handles editing of username
  Future<void> _editUsername() async {
    TextEditingController _usernameController =
    TextEditingController(text: username);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Username'),
        content: TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            hintText: 'Enter new username',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              String newUsername = _usernameController.text.trim();
              if (newUsername.isNotEmpty && newUsername.length >= 3) {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(targetUserId)
                      .update({
                    'username': newUsername,
                  });

                  setState(() {
                    username = newUsername;
                  });

                  Navigator.pop(context);
                  _showSuccessDialog(
                      'Success', 'Username updated successfully!');
                } catch (e) {
                  developer.log('Error updating username: $e');
                  _showErrorDialog(
                      'Error', 'Failed to update username. Please try again.');
                }
              } else {
                _showErrorDialog('Invalid Input',
                    'Username must be at least 3 characters long.');
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Handles editing of bio
  Future<void> _editBio() async {
    TextEditingController _bioController = TextEditingController(text: bio);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Bio'),
        content: TextField(
          controller: _bioController,
          decoration: InputDecoration(
            hintText: 'Enter your bio',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              String newBio = _bioController.text.trim();
              if (newBio.length <= 150) {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(targetUserId)
                      .update({
                    'bio': newBio,
                  });

                  setState(() {
                    bio = newBio;
                  });

                  Navigator.pop(context);
                  _showSuccessDialog('Success', 'Bio updated successfully!');
                } catch (e) {
                  developer.log('Error updating bio: $e');
                  _showErrorDialog(
                      'Error', 'Failed to update bio. Please try again.');
                }
              } else {
                _showErrorDialog(
                    'Invalid Input', 'Bio cannot exceed 150 characters.');
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure that targetUserId is set correctly
    if (targetUserId.isEmpty) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      // Added gradient background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: widget.userId == null && currentUser == null
            ? Center(child: CircularProgressIndicator())
            : SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              SizedBox(height: 16),
              _buildProfileHeader(),
              SizedBox(height: 16),
              _buildTabs(),
              _buildTabViews(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 3, // Assuming ProfileScreen is at index 3
      ),
    );
  }
}
