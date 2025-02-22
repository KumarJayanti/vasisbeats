import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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

  static const FirebaseOptions web = FirebaseOptions(
      apiKey: "AIzaSyBo7cHoleVLzP_TuxBqLOCQS_79SeZs5rg",
      authDomain: "vasis-beats.firebaseapp.com",
      projectId: "vasis-beats",
      storageBucket: "vasis-beats.firebasestorage.app",
      messagingSenderId: "971357659383",
      appId: "1:971357659383:web:69f2d93014447d40f873f2");

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyCiNSykhomSxEdwu8xs7LTJER33C-jF1h0",
    appId: "1:971357659383:android:063a7f908c71c920f873f2",
    messagingSenderId: "971357659383",
    projectId: 'vasis-beats',
    storageBucket: 'vasis-beats.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB6UkA1jZ8zAtXJNBJJZ51F6VL4dx2xozI',
    appId: '1:971357659383:ios:a764be80950ce422f873f2',
    messagingSenderId: '971357659383',
    projectId: 'vasis-beats',
    storageBucket: 'vasis-beats.appspot.com',
    iosClientId: '971357659383-vq98f5ivlngp7e43qud65n2ri8jro0ps.apps.googleusercontent.com',
    iosBundleId: 'dev.spiritsoft.flutterAudioServiceDemo',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB6UkA1jZ8zAtXJNBJJZ51F6VL4dx2xozI',
    appId: '1:971357659383:ios:13698d552fe86715f873f2',
    messagingSenderId: '971357659383',
    projectId: 'vasis-beats',
    storageBucket: 'vasis-beats.appspot.com',
    iosClientId: '971357659383-evc5j8r3paoi0fpcdvhnt6ph09nopjnu.apps.googleusercontent.com',
    iosBundleId: 'com.spiritsoft.FlutterAudio',
  );
}
