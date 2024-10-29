import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Viewmodels/Auth_viewmodels.dart';

class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("WeeklyFeature Home"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              Navigator.of(context).pushReplacementNamed('/sign-in');
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          "Welcome to WeeklyFeature!",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
