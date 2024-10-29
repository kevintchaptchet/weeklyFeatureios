// File: weeklyfeature/routes/route.dart

import 'package:flutter/material.dart';
import '../views/splash_screen.dart';
import '../views/welcome.dart';
import '../Views/Presentation.dart';
import '../Views/Sign_in_page.dart';
import '../Views/Sign_up_page.dart';
import '../Features/Baddie_or_Studs/Views/Baddie_or_studs_dashboard.dart';
import '../Features/Baddie_or_Studs/Routes/routes.dart';

class AppRoutes {
  static const String splashScreen = '/';
  static const String welcomeScreen = '/welcome';
  static const String presentationScreen ='/presentation';
  static const String SignIn = '/SignIn';
  static const String SignUp = '/SignUp';
  static const String Baddies_or_studs = '/Baddies_or_studs';
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splashScreen:
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case presentationScreen:
        return
            MaterialPageRoute(builder: (_)=> PresentationScreen());
      case Baddies_or_studs:
        return MaterialPageRoute(builder: (_) => BaddiesOrStudsDashboard());
      case SignIn :
        return MaterialPageRoute(builder: (_) => SignInPage());
      case SignUp :
        return MaterialPageRoute(builder: (_)=> SignUpPage());
      case welcomeScreen:
        return MaterialPageRoute(builder: (_) => WelcomeScreen());
      default:
    final route = BaddieRoutes.generateRoute(settings);
    if (route != null) return route;

    return MaterialPageRoute(
    builder: (_) => Scaffold(
    body: Center(child: Text('No route defined for ${settings.name}'))));

    }
  }
}

