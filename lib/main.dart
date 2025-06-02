import 'package:flutter/material.dart';
import 'page_manager.dart';
import 'services/service_locator.dart';
import 'package:catcher/catcher.dart';

import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'screens/sign_in_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apps = Firebase.apps;
  if (apps.isEmpty) {
    await Firebase.initializeApp();
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
        EmailManualHandler(["kumar.jayanti@gmail.com"])
      ],
    ),
    releaseConfig: CatcherOptions(
      PageReportMode(showStackTrace: true),
      [
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

class _MyAppState extends State<MyApp> {
  //we can optimize  this by checking filesytem here.
  var _beatsReady = false;
  var _initializationDone = Future.value(true);

  @override
  void initState() {
    super.initState();
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
          if (user == null) {
            return EmailLinkSignInScreen(beatsReady: _beatsReady);
          }

          print("Firebase user: ${FirebaseAuth.instance.currentUser}");
          print("Beats ready: $_beatsReady");

          return ProfileScreen(beatsReady: _beatsReady); // 🔁 go here instead of SplashScreen or HomeScreen
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
