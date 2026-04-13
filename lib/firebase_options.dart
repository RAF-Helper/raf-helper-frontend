import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase config. Fill from Firebase Console → Project Settings → Your apps.
/// Or run: flutterfire configure
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA97Ydg7xkvlCSJbwTwXPRDG_PFRODOi1o',
    appId: '1:194490968007:web:f22205896f2306275bdbe2',
    messagingSenderId: '194490968007',
    projectId: 'rafhelper',
    authDomain: 'rafhelper.firebaseapp.com',
    storageBucket: 'rafhelper.firebasestorage.app',
  );

  // Firebase Console → Project Settings → Web app

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCm0-oQqAsPedy1K1f4YhsxaDN_aa67CNU',
    appId: '1:194490968007:android:0c8220c4d072b4cf5bdbe2',
    messagingSenderId: '194490968007',
    projectId: 'rafhelper',
    storageBucket: 'rafhelper.firebasestorage.app',
  );

  // Firebase Console → Project Settings → Android app

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCHfEXtHAjBh9lqkbs3aMfh5PuJG1UNzuI',
    appId: '1:194490968007:ios:e6fb74e1293ae0105bdbe2',
    messagingSenderId: '194490968007',
    projectId: 'rafhelper',
    storageBucket: 'rafhelper.firebasestorage.app',
    iosBundleId: 'com.example.RafHelper',
  );

  // Firebase Console → Project Settings → iOS app
}