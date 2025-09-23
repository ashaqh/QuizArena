# QuizArena

A Kahoot-like quiz application built with Flutter and Firebase.

## ✨ Features

- **Real-time Multiplayer Quizzes**: Host and join live quiz sessions
- **Firebase Authentication**: Secure user login and registration
- **Cloud Storage**: Quiz data synced across all devices
- **Image Support**: Upload images directly from your device for quiz questions
- **Responsive Design**: Works on mobile devices, tablets, and web
- **Live Scoring**: Real-time leaderboards and scoring

## 📱 Image Upload Feature

QuizArena now supports adding images to quiz questions:

- **Device Upload**: Choose images from your camera or gallery
- **Cloud Storage**: Images are securely stored in Firebase Storage
- **Cross-Device Sync**: Images appear on all participants' devices
- **Responsive Display**: Images automatically resize to fit screens

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase Setup

This app uses Firebase for backend services including Firestore and Authentication.

### Prerequisites
- Firebase account
- Firebase CLI installed (`npm install -g firebase-tools`)

### Setup Steps

1. **Login to Firebase:**
   ```
   firebase login
   ```

2. **Create Firebase Project:**
   ```
   firebase projects:create quizarena
   ```

3. **Enable Firestore and Authentication:**
   - Go to Firebase Console (https://console.firebase.google.com)
   - Select the 'QuizArena' project
   - Enable Firestore Database
   - Enable Authentication (Email/Password provider)

4. **Add Apps to Firebase Project:**
   - **Android:** Add Android app with package name `com.example.quizarena`
   - **iOS:** Add iOS app with bundle ID `com.example.quizarena`
   - **Web:** Add Web app
   - **Windows:** Firebase does not officially support Windows, but you can configure it similarly if needed

5. **Download Configuration Files:**
   - **Android:** Download `google-services.json` and place it in `android/app/`
   - **iOS:** Download `GoogleService-Info.plist` and place it in `ios/Runner/`
   - **Web:** Download `firebase_options.dart` and place it in `lib/` (uncomment the options in main.dart)
   - **Windows:** No specific config file needed

6. **Run the App:**
   ```
   flutter run
   ```

The app will initialize Firebase and set up basic Firestore collections (quizzes, games, players) with sample data on first run.
