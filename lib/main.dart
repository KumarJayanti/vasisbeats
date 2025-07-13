import 'package:flutter/material.dart';
import 'page_manager.dart';
import 'services/service_locator.dart';
import 'package:catcher/catcher.dart';

import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'screens/sign_in_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    if (Platform.isMacOS || Platform.isIOS) {
      await Firebase.initializeApp(); // auto-loads from plist
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  await setupServiceLocator();

  Catcher(
    rootWidget: ChangeNotifierProvider(
      create: (_) => DownloadProgress(),
      child: MyApp(),
    ),
    debugConfig: CatcherOptions(
      PageReportMode(showStackTrace: true),
      [
        ConsoleHandler(),
        EmailManualHandler(["kumar.jayanti@gmail.com"])
      ],
    ),
    releaseConfig: CatcherOptions(
      PageReportMode(showStackTrace: true),
      [
        ConsoleHandler(),
        EmailManualHandler(["kumar.jayanti@gmail.com"])
      ],
    ),
  );
}

class DownloadProgress extends ChangeNotifier {
  double _percentDownloaded = 0.0;
  String _path = "";

  double get percentDownloaded => _percentDownloaded;
  String get path => _path;

  void updateProgress(double value, String path) {
    _percentDownloaded = value;
    _path = path;
    notifyListeners();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}
//https://storage.googleapis.com/vasis/vasis-sounds.zip
//https://storage.googleapis.com/vasis/last_updated.txt
//https://storage.googleapis.com/vasis/vasis-sounds-paid.zip

class _MyAppState extends State<MyApp> {
  late Future<bool> _initializationDone;
  //we can optimize  this by checking filesytem here.
  var _beatsReady = false;
  final String _kStoredEmailKey = 'email_for_signin';
  final AppLinks _appLinks = AppLinks();

  Future<String?> getStoredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kStoredEmailKey);
  }

  void initDeepLinkHandler() {
  // This stream emits links when the app is running or resumed.
  _appLinks.uriLinkStream.listen((Uri uri) async {
    print('[DeepLink] Received URI: ' + uri.toString());
    // SNACKBAR DEBUG START
    final ctx = Catcher.navigatorKey.currentState?.overlay?.context;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('[DeepLink] Received URI: ${uri.toString()}')),
      );
    }
    // SNACKBAR DEBUG END
    if (uri != null && FirebaseAuth.instance.isSignInWithEmailLink(uri.toString())) {
      final email = await getStoredEmail();
      print('[DeepLink] Found email: ' + (email ?? 'null'));
      // SNACKBAR DEBUG START
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('[DeepLink] Found email: ${email ?? 'null'}')),
        );
      }
      // SNACKBAR DEBUG END
      if (email != null) {
        try {
          final cred = await FirebaseAuth.instance.signInWithEmailLink(
            email: email,
            emailLink: uri.toString(),
          );
          print('[DeepLink] signInWithEmailLink SUCCESS: ${cred.user?.uid ?? "NO USER"}');
          // SNACKBAR DEBUG START
          if (ctx != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text('[DeepLink] signInWithEmailLink SUCCESS: ${cred.user?.uid ?? "NO USER"}')),
            );
          }
          // SNACKBAR DEBUG END
        } catch (e) {
          print('[DeepLink] signInWithEmailLink ERROR: $e');
          // SNACKBAR DEBUG START
          if (ctx != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text('[DeepLink] signInWithEmailLink ERROR: $e')),
            );
          }
          // SNACKBAR DEBUG END
        }
      } else {
        print("[DeepLink] No email found for sign-in");
        // SNACKBAR DEBUG START
        if (ctx != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('[DeepLink] No email found for sign-in')),
          );
        }
        // SNACKBAR DEBUG END
      }
    } else {
      print('[DeepLink] URI is not a valid sign-in link');
      // SNACKBAR DEBUG START
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('[DeepLink] URI is not a valid sign-in link')),
        );
      }
      // SNACKBAR DEBUG END
    }
  });
}


  @override
  void initState() {
    super.initState();
    if (!Platform.isMacOS) {
      initDeepLinkHandler();
    }
    _initializationDone = _initUserProfile();
  }

  Future<bool> _initUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("🚫 No user signed in yet");
        return true; // Nothing to initialize
      }

      final uid = user.uid;
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      final userSnapshot = await userDoc.get();

      // Check if user is in the 'admins' collection
      final isAdmin = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get()
          .then((doc) => doc.exists);

      if (!userSnapshot.exists) {
        final userEmail = user.email ?? "";
        final userName = userEmail.split('@').first;
        await userDoc.set({
          'userId': uid,
          'userName': userName,
          'email': user.email ?? '',
          'role': isAdmin ? 'admin' : 'user',
          'account_type': isAdmin ? 'paid' : 'free',
          'donation_amount': isAdmin ? 9999.0 : 0.0,
          'created_at': FieldValue.serverTimestamp(),
        });
        print("🆕 Created Firestore user doc for $uid");
      } else {
        print("✅ User doc already exists for $uid");
      }

      return true;
    } catch (e, st) {
      print("❌ Error initializing user profile: $e");
      print(st);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: Catcher.navigatorKey,
      title: 'Vasis Studio App',
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: _initializationDone,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = FirebaseAuth.instance.currentUser;
          print("user: $user");
          if (user == null) {
            return EmailLinkSignInScreen(beatsReady: _beatsReady);
          }

          return ProfileScreen(beatsReady: _beatsReady);
        },
      ),
    );
  }
}

class AddRemoveSongButtons extends StatelessWidget {
  const AddRemoveSongButtons({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingActionButton.extended(
            onPressed: pageManager.add,
            icon: Icon(
              Icons.add_circle_outline_rounded,
              size: 30,
            ),
            label: Text('Playlist'),
          ),
          FloatingActionButton.extended(
            onPressed: pageManager.remove,
            icon: Icon(Icons.remove_circle_outline_rounded, size: 30),
            label: Text('Playlist'),
          ),
        ],
      ),
    );
  }
}
