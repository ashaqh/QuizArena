import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'host/quiz_list_screen.dart';
import 'player/join_game_screen.dart';
import 'auth/login_screen.dart';
import '../services/auth_service.dart';

/// Home screen with role selection for QuizArena
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAnonymous = user?.isAnonymous ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuizArena'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (!isAnonymous)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
              tooltip: 'Logout',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to QuizArena${!isAnonymous && user!.displayName != null ? ', ${user.displayName}' : ''}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              const Text('Choose your role:', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _navigateToHost(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Host', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => _navigateToPlayer(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Player', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigate to host screen
  void _navigateToHost(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuizListScreen()),
    );
  }

  /// Navigate to player screen
  void _navigateToPlayer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const JoinGameScreen()),
    );
  }

  /// Logout user
  Future<void> _logout(BuildContext context) async {
    try {
      final authService = AuthService();
      // The authService.signOut() now has its own internal try-catch and logging
      await authService.signOut(); 
      debugPrint('HomeScreen: authService.signOut() call completed.');

      // Check current user status IMMEDIATELY after sign out
      final currentUserAfterSignOut = FirebaseAuth.instance.currentUser;
      debugPrint('HomeScreen: currentUser after authService.signOut(): ${currentUserAfterSignOut?.uid ?? 'null'}');

      // Navigate back to login screen
      // Add a mounted check for robustness, especially with async gaps
      if (!context.mounted) {
        debugPrint('HomeScreen: Context not mounted before navigation. Aborting navigation.');
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false, // Remove all previous routes
      );
      debugPrint('HomeScreen: Navigation to LoginScreen attempted.');

    } catch (e) { 
      // This 'e' is the network error if authService.signOut() rethrows, 
      // or an error from other operations in the try block.
      debugPrint('HomeScreen: Error during _logout process: $e');
      final currentUserAfterError = FirebaseAuth.instance.currentUser;
      debugPrint('HomeScreen: currentUser after error in _logout: ${currentUserAfterError?.uid ?? 'null'}');
      
      if (!context.mounted) {
         debugPrint('HomeScreen: Context not mounted for SnackBar. Aborting SnackBar.');
         return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e. Please check your network connection.'))
      );
    }
  }
}
