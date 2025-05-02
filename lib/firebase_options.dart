import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'BURAYA_WEB_API_KEY_YAZ',
    appId: '1:524418720034:android:60fae0c5961becbed7857b',
    messagingSenderId: '524418720034',
    projectId: 'todoapp-dc0af',
  );
}
