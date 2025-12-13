import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web {
    final env = dotenv.env;
    return FirebaseOptions(
      apiKey: env['FIREBASE_WEB_API_KEY']!,
      authDomain: env['FIREBASE_AUTH_DOMAIN']!,
      projectId: env['FIREBASE_PROJECT_ID']!,
      storageBucket: env['FIREBASE_WEB_STORAGE_BUCKET']!,
      messagingSenderId: env['FIREBASE_MESSAGING_SENDER_ID']!,
      appId: env['FIREBASE_WEB_APP_ID']!,
    );
  }

  static FirebaseOptions get android {
    final env = dotenv.env;
    return FirebaseOptions(
      apiKey: env['FIREBASE_ANDROID_API_KEY']!,
      appId: env['FIREBASE_ANDROID_APP_ID']!,
      messagingSenderId: env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: env['FIREBASE_PROJECT_ID']!,
      storageBucket: env['FIREBASE_STORAGE_BUCKET']!,
    );
  }

  static FirebaseOptions get ios {
    final env = dotenv.env;
    return FirebaseOptions(
      apiKey: env['FIREBASE_IOS_API_KEY']!,
      appId: env['FIREBASE_IOS_APP_ID']!,
      messagingSenderId: env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: env['FIREBASE_PROJECT_ID']!,
      storageBucket: env['FIREBASE_STORAGE_BUCKET']!,
      iosClientId: env['FIREBASE_IOS_CLIENT_ID']!,
      iosBundleId: env['FIREBASE_IOS_BUNDLE_ID']!,
    );
  }

  static FirebaseOptions get macos {
    final env = dotenv.env;
    return FirebaseOptions(
      apiKey: env['FIREBASE_MACOS_API_KEY']!,
      appId: env['FIREBASE_MACOS_APP_ID']!,
      messagingSenderId: env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: env['FIREBASE_PROJECT_ID']!,
      storageBucket: env['FIREBASE_STORAGE_BUCKET']!,
      iosClientId: env['FIREBASE_IOS_CLIENT_ID']!,
      iosBundleId: env['FIREBASE_IOS_BUNDLE_ID']!,
    );
  }
}
