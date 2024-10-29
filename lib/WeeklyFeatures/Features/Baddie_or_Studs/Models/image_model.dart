import 'package:flutter/material.dart';

class ImageModel {
  final String imageUrl;
  final double rating; // Rating from 0-10
  final String challengeId;

  ImageModel({
    required this.imageUrl,
    required this.rating,
    required this.challengeId,
  });

  // Method to get color based on rating
  static Color getRatingColor(double rating) {
    int red = ((1 - rating / 10) * 255).toInt();
    int green = (rating / 10 * 255).toInt();
    return Color.fromARGB(255, red, green, 0);
  }
}
