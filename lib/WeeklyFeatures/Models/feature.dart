// File: weeklyfeature/models/feature.dart

import 'package:flutter/material.dart';
import '../routes/route.dart';

class Feature {
  final String title;
  final String number;
  final Color color;
  final String route;

  Feature({required this.title, required this.number, required this.color, required this.route});
}

class FeatureWidget extends StatelessWidget {
  final Feature feature;

  FeatureWidget({required this.feature});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, feature.route);
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: feature.color,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                feature.number,
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            feature.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
