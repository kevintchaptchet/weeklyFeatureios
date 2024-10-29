import 'package:flutter/material.dart';
import '../Views/profile.dart';
import '../Views/search.dart';
import '../Views/Upload.dart';
import '../Views/create_challenge.dart';
import '../Views/Participate.dart';
import '../Views/result.dart';// Make sure this path is correct

class BaddieRoutes {
  static const String profile = '/profile';
  static const String search = '/search';
  static const String upload = '/upload';
  static const String create_challenge = '/create_challenge';
  static const String participate = '/participate';
  static const String result = '/result';



  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case result:
        return MaterialPageRoute(builder: (_) => Ranking());
      case participate :
        final challengeId = settings.arguments as String?;
        if (challengeId != null) {
          return MaterialPageRoute(
            builder: (_) => Participate(challengeId: challengeId), // Pass challengeId to Participate screen
          );
        } else {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('Error: No challenge ID provided')),
            ),
          );
        }
      case create_challenge:
        return MaterialPageRoute(builder: (_) => CreateChallengeScreen());
      case upload:
        return MaterialPageRoute(builder: (_) => UploadScreen());
      case search:
        return MaterialPageRoute(builder: (_) => SearchScreen());

      case profile:
        return MaterialPageRoute(builder: (_) => ProfileScreen());
    // Make sure to have a break or return here
      default:
      // Return a default route if no match is found
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No routesss defined for ${settings.name}')),
          ),
        );
    }
  }
}
