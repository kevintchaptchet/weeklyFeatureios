import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfServiceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms of Service',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            'Terms of Service for Weekly Features\n\n'
                'Last Updated: 27 October 2024\n\n'
            """ 

Terms of Service
Terms of Service for Weekly Features

Last Updated: 27 October 2024

1. Acceptance of Terms
By using Weekly Features, you agree to these terms. If you do not agree, discontinue app usage.

2. Use of Services
The app should be used only for its intended purpose. Unauthorized uses, such as data scraping, reverse engineering, or backend access, are prohibited.

3. User-Generated Content
Any content you upload is your responsibility. We may remove content that violates our guidelines.

4. Account Suspension or Termination
We reserve the right to suspend or terminate accounts if terms are violated or harmful behavior is detected.

5. Limitation of Liability
To the extent permitted by law, we are not liable for damages resulting from app use or access issues.

6. Modifications to Terms
We may modify these terms periodically. Continued use after changes implies acceptance.

Contact Us
For questions, reach out to kevintchap@gmail.com"""
            ,
            style: GoogleFonts.roboto(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
