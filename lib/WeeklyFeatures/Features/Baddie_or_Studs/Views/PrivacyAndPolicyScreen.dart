import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            'Privacy Policy for Weekly Features\n\n'
                'Last Updated: 27 October 2024\n\n'
            """ Privacy Policy
Privacy Policy for Weekly Features

Last Updated: 27 October 2024

1. Information Collection
We collect information you provide directly when using Weekly Features, such as your name, email address, profile picture, and any data you submit voluntarily. We may also gather data on your app interactions and preferences.

2. How We Use Your Information
We use this data to provide, improve, and personalize the app’s features and to communicate updates, new features, or changes in service.

3. Sharing and Disclosure
Your personal information is not shared with third parties unless necessary to comply with legal obligations, prevent fraud, or enforce our policies.

4. Data Security
We implement reasonable measures to secure your data. However, as electronic storage is not 100% secure, we cannot guarantee absolute data security.

5. Your Rights
You can access, correct, or delete your data stored with us. You may also request processing restrictions in specific cases.

6. Changes to this Privacy Policy
This policy may be updated periodically. Changes will be posted here, and continued use of Weekly Features signifies acceptance.

Contact Us
For any questions, please contact us at kevintchap@gmail.com.

"""
            ,
            style: GoogleFonts.roboto(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
