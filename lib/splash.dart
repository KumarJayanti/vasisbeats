import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'main.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'home.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class SplashScreen extends StatefulWidget {
  final String userStatus;
  const SplashScreen({Key? key, required this.userStatus}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false; // <-- Flag to ensure only one navigation
  bool _downloading = false;
  bool _beatsReady = false;
  bool _metadataMissing = false;
  String _dir = "";

  // --- USER STATUS LOGIC ---
  String _userStatus = ""; // TODO: Set this based on your actual user logic
  String _zipPath = 'https://storage.googleapis.com/vasis/vasis-sounds.zip';
  //String _paidZipPath =
  //    'https://storage.googleapis.com/vasis/vasis-sounds-paid.zip';
  String _paidZipPath = ''; // or null-safe as needed

  String _last_updated =
      'https://storage.googleapis.com/vasis/last_updated.txt';
  String _localZipFileName = 'vasis-sounds.zip';
  String _localUpdatedFileName = 'last_updated.txt';
  String _userStatusFileName = 'user_status.txt';

  @override
  void initState() {
    super.initState();
    _userStatus = widget.userStatus;
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        // Wait until the auth token is ready
        final idtoken = await user.getIdToken(true);
        //print('✅ Firebase ID token: $idtoken');
        _startBeatsCheck();
      } else {
        print("❌ No signed-in user available yet.");
      }
    });
  }

  void _startBeatsCheck() {
    _prepareApp();
  }

  /*
  Future<String> _getDownloadUrl(
      bool useSignedUrl, String fallbackUrl, String filePath) async {
    if (!useSignedUrl) return fallbackUrl;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No FirebaseAuth user available for signed URL. Falling back.');
        return fallbackUrl;
      }

      // 🔐 Force a token refresh. This is the key to fixing the "unauthenticated"
      // error by ensuring a valid ID token is ready for the Cloud Function call.
      print('Requesting fresh ID token before calling getSignedUrl...');
      await user.getIdToken(true);
      print('✅ ID token is fresh.');

      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('getSignedUrl');
      final result = await callable.call({'filePath': filePath});
      print('✅ Successfully got signed URL from function.');
      return result.data['url'];
    } catch (e) {
      print('❌ Error getting signed URL, falling back to public URL: $e');
      if (fallbackUrl.isEmpty) {
        print('⚠️ No fallback URL available. Download will likely fail.');
      }
      return fallbackUrl;
    }
  }
  */
  //

  Future<String> _getDownloadUrl(
    bool useSignedUrl, String fallbackUrl, String filePath) async {
  if (!useSignedUrl) {
    print("ℹ️ Not using signed URL, falling back to: $fallbackUrl");
    return fallbackUrl;
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print("⚠️ No Firebase user signed in, using fallback: $fallbackUrl");
    return fallbackUrl;
  }

  try {
    final idToken = await user.getIdToken();
    final uri = Uri.parse(
        "https://us-central1-vasis-beats.cloudfunctions.net/getSignedUrl");

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $idToken",
      },
    );

    if (response.statusCode == 200) {
      final url = jsonDecode(response.body)['url'];
      print("✅ Got signed URL: $url");
      return url;
    } else {
      print("❌ Failed to get signed URL (${response.statusCode}): ${response.body}");
    }
  } catch (e, st) {
    print("❌ Exception getting signed URL: $e");
    print(st);
  }

  print("⚠️ Falling back to: $fallbackUrl");
  return fallbackUrl;
}


  Future<void> _writeUserStatusFile(String status) async {
    final file = File('$_dir/$_userStatusFileName');
    await file.writeAsString(status);
  }

  Future<String?> _readUserStatusFile() async {
    final file = File('$_dir/$_userStatusFileName');
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  Future<void> _deleteVasisFolderAndMeta() async {
    final vasisDir = Directory('$_dir/vasis');
    if (await vasisDir.exists()) {
      await vasisDir.delete(recursive: true);
    }
    final lastUpdatedFile = File('$_dir/last_updated.txt');
    if (await lastUpdatedFile.exists()) {
      await lastUpdatedFile.delete();
    }
  }

  Future<bool> _prepareApp() async {
    _dir = (await getApplicationDocumentsDirectory()).path;
    print("app dir=" + _dir);

    // --- USER STATUS LOGIC START ---
    bool forceDownload = false;
    String? previousStatus = await _readUserStatusFile();
    if (previousStatus == null || previousStatus != _userStatus) {
      // Status changed or first run
      await _deleteVasisFolderAndMeta();
      await _writeUserStatusFile(_userStatus);
      forceDownload = true;
    }
    // Set correct zip URL and filename
    if (_userStatus == "paid") {
      _zipPath = _paidZipPath;
      _localZipFileName = 'vasis-sounds-paid.zip';
    } else {
      _zipPath = 'https://storage.googleapis.com/vasis/vasis-sounds.zip';
      _localZipFileName = 'vasis-sounds.zip';
    }
    // --- USER STATUS LOGIC END ---

    if (forceDownload) {
      await _initBeatsReady(forceDownload: true);
      return true;
    }
    bool needToDownloadZip = await _needToDownloadZip();
    if (!_navigated && !needToDownloadZip) {
      _beatsReady = true;
      Provider.of<DownloadProgress>(context, listen: false)
          .updateProgress(1.0, _dir);
      return true;
    }
    await _initBeatsReady();
    return true;
  }

  _initDir() async {
    _dir = (await getApplicationDocumentsDirectory()).path;
    print("app dir=" + _dir);
  }

  Future<bool> _needToDownloadZip() async {
    print("Entry needToDownloadZip.....");
    bool fileExists = await File('$_dir/last_updated.txt').exists();
    String currentDate;
    bool toDownloadZip = true;
    if (fileExists) {
      print("last_updated file already exists");
      File current = await File('$_dir/last_updated.txt');
      currentDate = await current.readAsString();
      print("currentDate=" + currentDate);
      var lastUpdated =
          await _downloadFile(_last_updated, _localUpdatedFileName);
      String latestDate = await lastUpdated.readAsString();
      print("latestDate=" + latestDate);
      if (latestDate.compareTo(currentDate) == 0) {
        print("latestDate date is same as currentDate, no download needed..");
        toDownloadZip = false;
      }
    }
    print("Exit needToDownloadZip.....:$toDownloadZip");
    return toDownloadZip;
  }

  _initBeatsReady({bool forceDownload = false}) async {
    print("Entry _initBeatsReady.....");
    await _initDir();
    /*
     if last_updated.txt is not present in Application Documents Dir then download it and the zip
     if last_updated.txt is present, then find its date (content), download last_updated as well
     check if existing download date is equal to the one downloaded, if equal then skip download and set beatsready
     if new then : remove existing, download zip and set beatsready
    */
    bool fileExists = await File('$_dir/last_updated.txt').exists();
    String currentDate;
    bool toDownloadZip = false;
    if (fileExists) {
      print("last_updated file already exists");
      File current = await File('$_dir/last_updated.txt');
      currentDate = await current.readAsString();
      print("currentDate=" + currentDate);
      var lastUpdated =
          await _downloadFile(_last_updated, _localUpdatedFileName);
      String latestDate = await lastUpdated.readAsString();
      print("latestDate=" + latestDate);
      if (latestDate.compareTo(currentDate) > 0) {
        print("latestDate date is greater than currentDate");
        toDownloadZip = true;
      }
    } else {
      print("last_updated file does not exist");
      var lastUpdated =
          await _downloadFile(_last_updated, _localUpdatedFileName);
      toDownloadZip = true;
    }
    print("toDownloadZip=$toDownloadZip");
    if (toDownloadZip || forceDownload) {
      await _downloadZip();
    } else {
      _beatsReady = true;
    }

    bool metadatajson = await File('$_dir/vasis/metadata.json').exists();
    if (!metadatajson) {
      _metadataMissing = true;
    }
    print("_metadataMissing=$_metadataMissing");
  }

  Future<File> _downloadFile(String url, String fileName) async {
    var req = await http.Client().get(Uri.parse(url));
    var file = File('$_dir/$fileName');
    //By default writeAsBytes creates the file for writing and truncates the file if it already exists
    return file.writeAsBytes(req.bodyBytes);
  }

  //--------------
  Future<File> _downloadZippedFile({
    required bool useSignedUrl,
    required bool isPaidFilePath,
  }) async {
    final fileName =
        isPaidFilePath ? 'vasis-sounds-paid.zip' : 'vasis-sounds.zip';
    final fallbackUrl = isPaidFilePath ? _paidZipPath : _zipPath;
    //print("_downloadZippedFile : fileName=$fileName");
    final url = await _getDownloadUrl(useSignedUrl, fallbackUrl, fileName);
    //print("_downloadZippedFile : url=$url");
    final req = await http.Client().send(http.Request('GET', Uri.parse(url)));
    final file = File('$_dir/$fileName');
    //print("Directory _dir= $_dir");

    final responseStream = req.stream;
    final totalBytes = req.contentLength ?? 0;
    var bytesDownloaded = 0;
    final fileSink = file.openWrite();
    
    await for (final chunk in responseStream) {
      bytesDownloaded += chunk.length;
      fileSink.add(chunk);
      //print("_downloadZippedFile : bytesDownloaded=$bytesDownloaded");
      final progress = bytesDownloaded / totalBytes;
      Provider.of<DownloadProgress>(context, listen: false)
          .updateProgress(progress, _dir);
    }
    //print("_downloadZippedFile : totalBytes=$totalBytes");
    await fileSink.close();
    return file;
  }

  //--------------

  Future<File> _downloadZippedFileOld(String url, String fileName) async {
    final req = await http.Client().send(http.Request('GET', Uri.parse(url)));
    final file = File('$_dir/$fileName');
    print("Directory _dir= $_dir");
    final responseStream = req.stream;
    final totalBytes = req.contentLength ?? 0;
    var bytesDownloaded = 0;

    final fileSink = file.openWrite();

    await for (final chunk in responseStream) {
      bytesDownloaded += chunk.length;
      fileSink.add(chunk);
      final progress = bytesDownloaded / totalBytes;
      Provider.of<DownloadProgress>(context, listen: false)
          .updateProgress(progress, _dir);
    }

    await fileSink.close();
    return file;
  }

  /*
  Future<void> _downloadZip() async {
    if (_downloading) {
      return;
    }

    _downloading = true;

    var zippedFile = await _downloadZippedFile(_zipPath, _localZipFileName);
    print("zipped file path=");
    print(zippedFile.path);
    await unarchiveAndSave(zippedFile);
    _downloading = false;
    _beatsReady = true;
  }*/

  Future<void> _downloadZip() async {
    if (_downloading) return;
    _downloading = true;

    final isPaid = _userStatus == "paid";
    final zippedFile = await _downloadZippedFile(
      useSignedUrl: isPaid, // use signed URL only for paid users
      isPaidFilePath: isPaid, // determines which file name to pass
    );

    print("zipped file path=${zippedFile.path}");
    await unarchiveAndSave(zippedFile);
    _downloading = false;
    _beatsReady = true;
  }

  unarchiveAndSave(var zippedFile) async {
    var bytes = zippedFile.readAsBytesSync();
    var archive = ZipDecoder().decodeBytes(bytes);
    for (var file in archive) {
      var fileName = '$_dir/${file.name}';
      if (file.isFile) {
        var outFile = File(fileName);
        //print('File:: ' + outFile.path);
        outFile = await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content);
      }
    }
    //delete zip file
    print("Deleting zip file");
    await zippedFile.delete();
  }

  static const colorizeColors = [
    Colors.purple,
    Colors.blue,
    Colors.yellow,
    Colors.red,
  ];

  static const colorizeTextStyle = TextStyle(
    fontSize: 20.0,
    fontFamily: 'Horizon',
  );

  Future<void> cleanUpDocumentsDirectory(String path) async {
    Directory documentsDir = Directory(path);
    List<FileSystemEntity> files = documentsDir.listSync(recursive: false);
    for (var file in files) {
      if (file is File) await file.delete();
    }
  }

  void exitApp() {
    exit(0);
  }

  void _navigateOnceDownloadComplete(DownloadProgress dp) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_navigated && dp.percentDownloaded >= 1.0) {
        _navigated = true;
        try {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        } catch (e, stack) {
          debugPrint("Exception during  Navigation: $e");
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadProgress>(
      builder: (context, downloadProgress, _) {
        _navigateOnceDownloadComplete(downloadProgress);
        final percent = downloadProgress.percentDownloaded * 100;
        final dir = downloadProgress.path;
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/vasis.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DefaultTextStyle(
                    style: const TextStyle(fontSize: 20.0),
                    child: AnimatedTextKit(
                      animatedTexts: [
                        ColorizeAnimatedText(
                          'Downloading Beats Files of size ~10MB, tap \u{261E} \u{274C} to STOP and Cleanup',
                          textStyle: colorizeTextStyle,
                          colors: colorizeColors,
                        )
                      ],
                      isRepeatingAnimation: true,
                      onTap: () {
                        cleanUpDocumentsDirectory(dir).then((_) {
                          exitApp();
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: 200,
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${percent.toStringAsFixed(1)}% Downloaded',
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                  SizedBox(height: 20),
                  DefaultTextStyle(
                    style: const TextStyle(fontSize: 15.0),
                    child: AnimatedTextKit(
                      animatedTexts: [
                        WavyAnimatedText('__/\\o_ Kirtan For Life _o/\\__',
                            textStyle: TextStyle(color: Colors.purple)),
                      ],
                      isRepeatingAnimation: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
