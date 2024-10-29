// lib/screens/SettingsScreen.dart
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weekly_features/WeeklyFeatures/Viewmodels/Auth_viewmodels.dart'; //
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For opening links
// Remove local imports for PrivacyPolicyScreen and TermsOfServiceScreen
// import '../Views/TermsofServicesScreen.dart';
// import '../Views/PrivacyAndPolicyScreen.dart';

class SettingsScreen extends ConsumerWidget {
  // Define your hosted URLs
  final String privacyPolicyUrl = 'https://weekly-features.web.app/privacy-policy.html';
  final String termsOfUseUrl = 'https://weekly-features.web.app/terms-of-use.html';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authViewModel = ref.read(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          children: [
            // Privacy Policy
            ListTile(
              leading: Icon(Icons.privacy_tip, color: Colors.white),
              title: Text(
                'Privacy Policy',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
              onTap: () {
                _launchURL(context, privacyPolicyUrl);
              },
            ),
            Divider(color: Colors.white54),
            // Terms of Use
            ListTile(
              leading: Icon(Icons.article, color: Colors.white),
              title: Text(
                'Terms of Use',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
              onTap: () {
                _launchURL(context, termsOfUseUrl);
              },
            ),
            Divider(color: Colors.white54),
            // Feature Requests
            ListTile(
              leading: Icon(Icons.feedback, color: Colors.white),
              title: Text(
                'Feature Requests',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
              onTap: () {
                _showFeatureRequestDialog(context);
              },
            ),
            Divider(color: Colors.white54),
            // Sign Out
            ListTile(
              leading: Icon(Icons.logout, color: Colors.white),
              title: Text(
                'Sign Out',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
              onTap: () async {
                await authViewModel.signOut(context);
              },
            ),
            Divider(color: Colors.white54),
          ],
        ),
      ),
    );
  }

  /// Opens a URL in the default browser or in-app WebView
  void _launchURL(BuildContext context, String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Opens in external browser
        // mode: LaunchMode.inAppWebView, // Uncomment to open in-app
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch the URL')),
      );
      developer.log('Could not launch $url');
    }
  }

  /// Shows a dialog for feature requests
  void _showFeatureRequestDialog(BuildContext context) {
    TextEditingController _featureController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Feature Request'),
        content: TextField(
          controller: _featureController,
          decoration: InputDecoration(
            hintText: 'Describe your feature request',
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
              String featureRequest = _featureController.text.trim();
              if (featureRequest.isNotEmpty) {
                try {
                  // Save the feature request to Firestore
                  await FirebaseFirestore.instance
                      .collection('feature_requests')
                      .add({
                    'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
                    'request': featureRequest,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Feature request submitted!')),
                  );
                } catch (e) {
                  developer.log('Error submitting feature request: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to submit request.')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a feature request.')),
                );
              }
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }
}
