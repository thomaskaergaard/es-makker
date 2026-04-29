import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firebase configuration for Es Makker.
///
/// HOW TO SET UP FIREBASE:
/// 1. Go to https://console.firebase.google.com/ and create a new project.
/// 2. In the project, click "Add app" and choose Web (</> icon).
/// 3. Register the app and copy the firebaseConfig values shown.
/// 4. Under "Build" → "Realtime Database", create a database.
///    Choose a region and start in Test mode (or set up security rules).
/// 5. Copy the Database URL (e.g. https://YOUR_PROJECT-default-rtdb.REGION.firebasedatabase.app)
/// 6. Replace every 'YOUR_...' placeholder below with your actual values.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions is only configured for Web. '
      'Add platform-specific options for other targets if needed.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    databaseURL: 'YOUR_DATABASE_URL',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  );
}
