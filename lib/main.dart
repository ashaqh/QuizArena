import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'widgets/main_navigation.dart';
import 'screens/auth/login_screen.dart';

/// Main entry point of the application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (optional - no longer required for AI)
  try {
    await dotenv.load(fileName: ".env");
    debugPrint(
      'Environment variables loaded successfully (optional for free AI)',
    );
  } catch (e) {
    debugPrint(
      'Environment variables not loaded (this is OK for free AI services): $e',
    );
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Run the app
  runApp(
    const ProviderScope(
      child: Directionality(textDirection: TextDirection.ltr, child: MyApp()),
    ),
  );
}

/// Root widget of the QuizArena application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuizArena',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          alignLabelWithHint: true,
        ),
      ),
      locale: const Locale('en', 'US'),
      supportedLocales: const [Locale('en', 'US')],
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.ltr, child: child!);
      },
      home: const SplashWrapper(),
    );
  }
}

/// Wrapper that shows splash screen then transitions to auth checking
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Show splash for 3 seconds then transition to auth wrapper
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }
    return const AuthWrapper();
  }
}

/// Wrapper widget that handles authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show splash screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // If user is authenticated, show main navigation
        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigationScreen();
        }

        // If no user, show login screen
        return const LoginScreen();
      },
    );
  }
}
