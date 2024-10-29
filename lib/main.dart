// File: weeklyfeature/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'WeeklyFeatures/Views/Welcome.dart';
import 'WeeklyFeatures/Routes/Route.dart';
import 'WeeklyFeatures/Views/onboarding_page.dart'; // Import OnboardingPage
import 'WeeklyFeatures/Views/home.dart'; // Import HomePage
import 'WeeklyFeatures/Views/Sign_in_page.dart'; // Import SignInPage
import 'WeeklyFeatures/Views/Sign_up_page.dart'; // Import SignUpPage
import 'WeeklyFeatures/Views/splash_screen.dart'; // Import SplashScreen
import 'firebase_options.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter/services.dart'; // For SystemChrome
import 'package:google_fonts/google_fonts.dart';
import 'WeeklyFeatures/Models/Users.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weekly_features/WeeklyFeatures/Features/Baddie_or_Studs/Views/Baddie_or_studs_dashboard.dart';

// Import AuthService and Providers
import 'WeeklyFeatures/services/auth_services.dart';
import 'WeeklyFeatures/Viewmodels/Auth_viewmodels.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Import flutter_dotenv
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Background message handler for Firebase Messaging
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp();
  // Handle background message
  print('Handling a background message: ${message.messageId}');
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Retrieve API keys from environment variables using flutter_dotenv
  final String? geminiKey = dotenv.env['GEMINI_API_KEY'];
  final String? stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
  // If using OpenAI

  // Validate required keys
  if (geminiKey == null || geminiKey.isEmpty) {
    throw Exception('GEMINI_API_KEY is not set in the environment variables.');
  }

  if (stripeKey == null || stripeKey.isEmpty) {
    throw Exception('STRIPE_PUBLISHABLE_KEY is not set in the environment variables.');
  }

  // Initialize Gemini
  try {
    await Gemini.init(apiKey: geminiKey);
    print('Gemini initialized successfully');
  } catch (e) {
    print('Error initializing Gemini: $e');
    // Handle initialization error appropriately, e.g., show an alert or fallback UI
  }

  // Initialize OpenAI (if used)


  // Initialize Stripe
  Stripe.publishableKey = stripeKey;
  // Optionally, initialize other Stripe settings here
  print('Stripe initialized successfully');

  // Set up Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    // If you have iOS settings, add them here
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    // You can add onSelectNotification callback if needed
  );

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission for notifications');
  } else {
    print('User declined or has not accepted notification permissions');
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    const String generalChannelId = 'general_notifications';
    const String generalChannelName = 'General Notifications';

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            generalChannelId,
            generalChannelName,
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false,
          ),
        ),
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    // Handle notification tap if needed
    print('Notification caused app to open: ${message.messageId}');
  });

  // Lock device orientation to portrait mode (optional)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(ProviderScope(child: MyApp()));
}

// Define a Global Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);

    return MaterialApp(
      title: 'WeeklyFeature',
      navigatorKey: navigatorKey, // Assign the navigator key
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      debugShowCheckedModeBanner: false, // Hide the debug banner
      home: InitializerWidget(), // Set the initial widget
      routes: {
        '/sign-in': (context) => SignInPage(),
        '/sign-up': (context) => SignUpPage(),
        '/onboarding': (context) => OnboardingPage(),
        '/home': (context) => HomePage(),
        '/splash': (context) => SplashScreen(),
        // Add other routes here
      },
      onGenerateRoute: AppRoutes.generateRoute, // Keep your existing route generator
    );
  }
}

/// **InitializerWidget** checks the user's authentication and onboarding status
/// and navigates them to the appropriate screen.
class InitializerWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<InitializerWidget> createState() => _InitializerWidgetState();
}

class _InitializerWidgetState extends ConsumerState<InitializerWidget> {
  @override
  void initState() {
    super.initState();
    // Any additional initialization can go here if needed
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.read(authServiceProvider);

    return FutureBuilder<UserModel?>(
      future: authService.getCurrentUserModel(),
      builder: (context, snapshot) {
        // Show a loading indicator while checking authentication status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen(); // Your custom splash/loading screen
        } else {
          if (snapshot.hasData && snapshot.data != null) {
            final user = snapshot.data!;
            if (!user.hasCompletedOnboarding) {
              // Navigate to OnboardingPage if onboarding not completed
              return OnboardingPage();
            } else {
              // Navigate to HomePage if onboarding already completed
              return WelcomeScreen();
            }
          } else {
            // If the user is not logged in, navigate to WelcomeScreen
            return WelcomeScreen();
          }
        }
      },
    );
  }
}
