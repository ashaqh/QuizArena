import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib/widgets/main_navigation.dart';
import 'lib/screens/splash_screen.dart';

void main() {
  runApp(const TestDashboardApp());
}

class TestDashboardApp extends StatelessWidget {
  const TestDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasData) {
            // User is signed in, show dashboard
            return const MainNavigationScreen(initialIndex: 2); // Stats tab
          } else {
            // User is not signed in, show splash
            return const SplashScreen();
          }
        },
      ),
    );
  }
}