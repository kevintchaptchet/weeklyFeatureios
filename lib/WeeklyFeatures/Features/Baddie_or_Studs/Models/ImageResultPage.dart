// ImageResultPage.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ImageResultPage extends StatelessWidget {
  final String imageUrl;
  final double rating;
  final String criteria;

  const ImageResultPage({
    Key? key,
    required this.imageUrl,
    required this.rating,
    required this.criteria,
  }) : super(key: key);

  // Function to get the dynamic color based on rating
  Color _getRatingColor(double rating) {
    // Ensure rating is within 0.0 to 10.0
    double clampedRating = rating.clamp(0.0, 10.0);
    int red = ((1 - clampedRating / 10) * 255).toInt();
    int green = (clampedRating / 10 * 255).toInt();
    return Color.fromARGB(255, red, green, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set a dark background for better contrast
      body: Stack(
        children: [
          // Main image with neon glow based on rating
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: _getRatingColor(rating),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(child: Text('Failed to load image', style: TextStyle(color: Colors.white)));
                },
              ),
            ),
          ),
          // Challenge criteria at the top
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Center(
              child: Text(
                'Challenge Criteria: $criteria',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: _getRatingColor(rating),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Rating display at the bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _getRatingColor(rating),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 5,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Rating: ${rating.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Back button
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
