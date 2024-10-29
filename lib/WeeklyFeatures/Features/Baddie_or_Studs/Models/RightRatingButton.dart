// lib/Models/RightRatingButton.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Ensure Firestore import

class RightRatingButton extends StatefulWidget {
  final Function(double) onRatingSelected;
  final double currentRating;
  final String uploadId; // To identify the document in Firestore
  final bool hasVoted; // To disable if the user has already voted
  final bool isSubmitting; // To indicate if a submission is in progress

  // Constructor with required parameters
  const RightRatingButton({
    Key? key,
    required this.onRatingSelected,
    required this.currentRating,
    required this.uploadId,
    required this.hasVoted,
    required this.isSubmitting,
  }) : super(key: key);

  @override
  _RightRatingButtonState createState() => _RightRatingButtonState();
}

class _RightRatingButtonState extends State<RightRatingButton>
    with SingleTickerProviderStateMixin {
  bool _isExpandedRight = false;
  late AnimationController _animationController;
  late Animation<double> _iconRotationAnimation;
  double _selectedRating = -1.0; // Initialize with an invalid rating

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _iconRotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  // Toggle the expansion of rating buttons
  void _toggleExpansionRight() {
    // Prevent expansion if already voted or submitting
    if (widget.hasVoted || widget.isSubmitting) return;

    if (!mounted) return;

    setState(() {
      _isExpandedRight = !_isExpandedRight;
      if (_isExpandedRight) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _selectedRating = -1.0; // Reset selected rating
      }
    });
  }

  // Function to handle rating selection
  Future<void> _updateRating(double userVote) async {
    if (!mounted) return;
    // Invoke the callback with the selected rating
    widget.onRatingSelected(userVote);
  }

  // Build the rating buttons (1-10)
  Widget _buildRatingButtons() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withOpacity(0.5), // Semi-transparent background
      ),
      child: SingleChildScrollView(
        reverse: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(10, (index) {
            int displayRating = index + 1;
            double ratingValue = displayRating.toDouble();
            bool isSelected = _selectedRating == ratingValue;

            return GestureDetector(
              onTap: () {
                widget.hasVoted ? null : _toggleExpansionRight;
                // Prevent voting if already voted or submitting
                if (widget.hasVoted || widget.isSubmitting) return;

                if (!mounted) return;

                setState(() {
                  _selectedRating = ratingValue;
                });
                _updateRating(ratingValue); // Update rating and save to Firestore
                _toggleExpansionRight(); // Collapse after selection
                _showSelectionAnimation(ratingValue);
              },
              child: AnimatedOpacity(
                opacity: _selectedRating == -1.0 || isSelected ? 1.0 : 0.3,
                duration: Duration(milliseconds: 300),
                child: Container(
                  width: 60, // Smaller width
                  height: 45, // Smaller height to fit all buttons
                  margin: EdgeInsets.all(4.0), // Remove spacing between buttons
                  decoration: BoxDecoration(
                    color: _getRatingColor(ratingValue),
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(
                      color: Colors.white,
                      width: 3,
                    )
                        : Border.all(
                      color: Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$displayRating',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 2,
                            color: Colors.black45,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).reversed.toList(),
        ),
      ),
    );
  }

  // Determine color based on rating value
  Color _getRatingColor(double rating) {
    if (rating <= 5) {
      int green = ((rating / 5) * 255).toInt();
      return Color.fromARGB(255, 255, green, 0);
    } else {
      int red = (((10 - rating) / 5) * 255).toInt();
      return Color.fromARGB(255, red, 255, 0);
    }
  }

  // Show a brief animation upon rating selection
  void _showSelectionAnimation(double rating) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.5, end: 1.5).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOut,
              ),
            ),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$rating',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );

    // Dismiss the dialog after the animation completes
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double _padding = 16.0;
    return Positioned(
      bottom: _padding,
      right: _padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Display rating buttons when expanded
          if (_isExpandedRight) _buildRatingButtons(),
          // Main button to toggle expansion
          GestureDetector(
            onTap: _toggleExpansionRight,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: (widget.hasVoted || widget.isSubmitting)
                    ? Colors.grey
                    : Colors.blueAccent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (widget.hasVoted || widget.isSubmitting)
                        ? Colors.grey.withOpacity(0.5)
                        : Colors.greenAccent.withOpacity(0.5),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: RotationTransition(
                turns: _iconRotationAnimation,
                child: Center(
                  child: widget.isSubmitting
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  )
                      : Icon(
                    Icons.star_rate,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
