import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'main.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'home.dart';

import 'package:flutter/services.dart';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false; // <-- Flag to ensure only one navigation
  bool _downloading = false;
  bool _beatsReady = false;
  bool _metadataMissing = false;
  String _dir = "";
  String _zipPath = 'https://storage.googleapis.com/vasis/vasis-sounds.zip';
  String _last_updated =
      'https://storage.googleapis.com/vasis/last_updated.txt';
  String _localZipFileName = 'vasis-sounds.zip';
  String _localUpdatedFileName = 'last_updated.txt';

  @override
  void initState() {
    super.initState();
    _startBeatsCheck();
  }

  void _startBeatsCheck() {
    _prepareApp();
  }

  Future<bool> _prepareApp() async {
    _dir = (await getApplicationDocumentsDirectory()).path;
    print("app dir=" + _dir);
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

  _initBeatsReady() async {
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
    if (toDownloadZip) {
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

  Future<File> _downloadZippedFile(String url, String fileName) async {
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
  }

 

  unarchiveAndSave(var zippedFile) async {
    var bytes = zippedFile.readAsBytesSync();
    var archive = ZipDecoder().decodeBytes(bytes);
    for (var file in archive) {
      var fileName = '$_dir/${file.name}';
      if (file.isFile) {
        var outFile = File(fileName);
        print('File:: ' + outFile.path);
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
