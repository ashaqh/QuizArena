import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    // For web, we need to pass the client ID from Google Cloud Console
    // Go to: https://console.cloud.google.com/apis/credentials
    // Find your "Web client (auto created by Google Service)"
    // Copy the Client ID and replace below
    _googleSignIn = GoogleSignIn(
      clientId:
          '707331379680-6mmj5ih7g61h142fldhg3v9oqphc2kql.apps.googleusercontent.com', // Replace with actual web client ID
    );
  }

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Register with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    try {
      debugPrint('AuthService: Attempting Google signOut...');
      await _googleSignIn.signOut(); // Google sign out first
      debugPrint('AuthService: Google signOut successful.');

      debugPrint('AuthService: Attempting Firebase signOut...');
      await _auth.signOut();
      debugPrint('AuthService: Firebase signOut successful.');
    } catch (e) {
      debugPrint('AuthService: Error during signOut: $e');
      // Consider rethrowing or a more specific error handling
      throw Exception('Sign out failed: $e'); 
    }
  }

  // Sign in anonymously
  Future<UserCredential> signInAnonymously() {
    return _auth.signInAnonymously();
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('AuthService: Starting Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      debugPrint('AuthService: Google user selected: ${googleUser?.email}');
      if (googleUser == null) {
        debugPrint('AuthService: User cancelled Google sign-in');
        return null;
      }

      debugPrint('AuthService: Getting authentication...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      debugPrint(
        'AuthService: Got access token: ${googleAuth.accessToken != null ? 'YES' : 'NO'}',
      );
      debugPrint(
        'AuthService: Got id token: ${googleAuth.idToken != null ? 'YES' : 'NO'}',
      );

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('AuthService: Signing in with Firebase...');
      final result = await _auth.signInWithCredential(credential);
      debugPrint(
        'AuthService: Firebase sign-in successful: ${result.user?.email}',
      );

      return result;
    } catch (e) {
      debugPrint('AuthService: Google sign-in failed: $e');
      throw Exception('Google sign-in failed: $e');
    }
  }
}
