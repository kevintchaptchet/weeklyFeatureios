import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weekly_features/WeeklyFeatures/Routes/Route.dart';
import '../Models/feature.dart';
import 'dart:async'; // For Timer

class PresentationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 7 days from now date for the Nostalgia countdown
    final DateTime unlockDate = DateTime.now().add(Duration(days: 7));
    final features = [
      Feature(
        title: 'Baddies and Studs',
        number: '1',
        color: Colors.blueAccent,
        route: AppRoutes.Baddies_or_studs,
        image: AssetImage('lib/WeeklyFeatures/Assets/Images/baddies_or_studs.webp'),
        isLocked: false,
        unlockDate: null, // Not locked
        description:
        'Welcome to Baddies and Studs! In this exciting feature, you have the opportunity to rate everything and receive an objective note. Whether it’s the best video game, the most beautiful girl in the world, the strongest Pokémon, or the best cartoon—your opinions matter! Dive in and let your voice be heard as you explore and evaluate a wide array of topics.',
      ),
      Feature(
        title: 'Nostalgia',
        number: '2',
        color: Colors.orangeAccent,
        route: AppRoutes.Baddies_or_studs, // Assuming a different route
        image: AssetImage('lib/WeeklyFeatures/Assets/Images/nostalgia.webp'),
        isLocked: true,
        unlockDate: unlockDate, // Locked for 7 days
        description:
        'Step back in time with Nostalgia! This feature allows you to revisit your favorite memories and classic moments. Relive the games, shows, and events that shaped your past. Stay tuned as this feature unlocks in just 7 days, bringing you a curated collection of timeless favorites to enjoy once again.',
      ),
      // Add more features as needed
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purpleAccent, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Reduced padding for more space
            child: Column(
              children: [
                // Title
                Text(
                  'Features',
                  style: GoogleFonts.pacifico(
                    fontSize: 32, // Slightly reduced font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8.0,
                        color: Colors.black26,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20), // Reduced spacing
                // Features Grid
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Dynamically adjust crossAxisCount based on screen width
                      int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                      double childAspectRatio = 3 / 4; // Adjust as needed

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount, // Responsive columns
                          crossAxisSpacing: 16, // Reduced spacing
                          mainAxisSpacing: 16,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: features.length,
                        itemBuilder: (context, index) {
                          return FeatureWidget(feature: features[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FeatureWidget extends StatefulWidget {
  final Feature feature;

  const FeatureWidget({Key? key, required this.feature}) : super(key: key);

  @override
  _FeatureWidgetState createState() => _FeatureWidgetState();
}

class _FeatureWidgetState extends State<FeatureWidget> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.feature.isLocked && widget.feature.unlockDate != null) {
      _updateTimeLeft();
      _timer = Timer.periodic(Duration(minutes: 1), (timer) {
        _updateTimeLeft();
      });
    }
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    final difference = widget.feature.unlockDate!.difference(now);
    if (difference.isNegative) {
      setState(() {
        _timeLeft = Duration.zero;
        _timer?.cancel();
      });
    } else {
      setState(() {
        _timeLeft = difference;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getCountdownText(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) {
      return 'Unlocked!';
    }
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    return '$days days, $hours hrs, $minutes mins left';
  }

  void _showFeatureDialog() {
    showDialog(
      context: context,
      builder: (context) {
        bool isLocked = widget.feature.isLocked && _timeLeft > Duration.zero;
        return AlertDialog(
          title: Text(
            widget.feature.title,
            style: GoogleFonts.lobster(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: widget.feature.color,
            ),
          ),
          content: Text(
            widget.feature.description,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            if (isLocked)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  _getCountdownText(_timeLeft),
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            TextButton(
              onPressed: isLocked
                  ? null
                  : () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushNamed(context, widget.feature.route);
              },
              child: Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          // Ensures the column takes minimum space needed
          mainAxisSize: MainAxisSize.min,
          children: [
            // The image inside the container with overlay if locked
            GestureDetector(
              onTap: () {
                _showFeatureDialog();
              },
              child: Stack(
                children: [
                  Container(
                    // Make height relative to available space
                    height: constraints.maxHeight * 0.6,
                    width: double.infinity, // Full width
                    decoration: BoxDecoration(
                      color: widget.feature.isLocked
                          ? Colors.grey.shade400
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image(
                        image: widget.feature.image,
                        fit: BoxFit.cover, // Ensure image covers the container
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.red,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (widget.feature.isLocked)
                    Container(
                      height: constraints.maxHeight * 0.6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 8),
            // Number and Title below the container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Feature Number
                  Flexible(
                    flex: 1,
                    child: Text(
                      widget.feature.number,
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 20, // Reduced font size
                        fontWeight: FontWeight.bold,
                        color: widget.feature.color,
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black26,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis, // Prevent overflow
                    ),
                  ),
                  SizedBox(width: 8),
                  // Feature Title (use Expanded to take available space)
                  Expanded(
                    flex: 3,
                    child: Text(
                      widget.feature.title,
                      style: GoogleFonts.lobster(
                        fontSize: 18, // Slightly reduced font size
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        shadows: [
                          Shadow(
                            blurRadius: 3.0,
                            color: Colors.grey,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis, // Prevent overflow
                      maxLines: 2, // Limit to two lines
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4),
            if (widget.feature.isLocked && _timeLeft > Duration.zero)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      color: Colors.white70,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getCountdownText(_timeLeft),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis, // Prevent overflow
                          maxLines: 1, // Single line
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// Feature Model Class
class Feature {
  final String title;
  final String number;
  final Color color;
  final String route;
  final AssetImage image;
  final bool isLocked;
  final DateTime? unlockDate; // Optional unlock date for locked features
  final String description; // Description of the feature

  Feature({
    required this.title,
    required this.number,
    required this.color,
    required this.route,
    required this.image,
    required this.isLocked,
    this.unlockDate,
    required this.description,
  });
}
