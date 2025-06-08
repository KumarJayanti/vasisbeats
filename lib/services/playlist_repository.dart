import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'beats_data.dart';
import 'dart:convert';

abstract class PlaylistRepository {
  Future<List<Map<String, String>>> fetchInitialPlaylist();
  Future<Map<String, String>> fetchAnotherSong();
}

class DemoPlaylist extends PlaylistRepository {
  static String baseURL = "";
  static String baseDir = "";
  static bool downloaded = false;
  static late List<dynamic> songsNew;

  _initDir() async {
    baseDir = (await getApplicationDocumentsDirectory()).path;
    if (Platform.isWindows) {
      baseDir = baseDir.replaceAll('\\', '/');
    }
    String downloadDir = baseDir + "/vasis/";
    //print(downloadDir);
    baseURL = "file://" + downloadDir;
    //downloaded = Directory(downloadDir).existsSync();
    //print('**********************');
    //print(baseURL);
    await _waitForMetadata(downloadDir);
    String metadataFile = downloadDir + "metadata.json";
    bool metadatajson = await File('$metadataFile').exists();
    if (!metadatajson) {
      throw "missing : $metadataFile";
    }
    var file = File(metadataFile);
    final contents = await file.readAsString();
    var data = json.decode(contents);

    print('**********************');
    //print(data);
    songsNew = data as List;
    //
    //print(songsNew.length);
  }

  Future<void> _waitForMetadata(String path, {int retries = 10}) async {
    final metadataFile = File('$path/metadata.json');
    if (await metadataFile.exists()) {
      print("_waitForMetadata metadata.json found");
    }
    while (retries-- > 0) {
      if (await metadataFile.exists()) return;
      print("_waitForMetadata metadata.json not found, retrying...");
      await Future.delayed(Duration(milliseconds: 200));
    }
    throw Exception('metadata.json did not appear in time');
  }

  @override
  Future<List<Map<String, String>>> fetchInitialPlaylist(
      {int length = 20}) async {
    if (baseURL.isEmpty) {
      await _initDir();
    }
    return List.generate(songsNew.length, (index) => _nextSong(baseURL));
  }

  @override
  Future<Map<String, String>> fetchAnotherSong() async {
    if (baseURL.isEmpty) {
      await _initDir();
    }
    return _nextSong(baseURL);
  }

  var _songIndex = 0;

  Map<String, String> _nextSong(String url) {
    var _maxSongNumber = songsNew.length;
    _songIndex = (_songIndex % _maxSongNumber);
    //print(url + songsNew[_songIndex]['url'].toString());
    if (!songsNew[_songIndex]['url'].toString().startsWith(url)) {
      songsNew[_songIndex]['url'] =
          url + songsNew[_songIndex]['url'].toString();
    }
    //print(songsNew[_songIndex]);
    Map<String, dynamic> retSong = songsNew[_songIndex++];
    Map<String, String> ret =
        retSong.map((key, value) => MapEntry(key, value.toString()));
    return ret;
  }
}
