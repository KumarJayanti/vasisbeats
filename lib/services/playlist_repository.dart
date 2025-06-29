import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'beats_data.dart';
import 'dart:convert';

abstract class PlaylistRepository {
  Future<List<Map<String, String>>> fetchInitialPlaylist({required String genre});
  Future<Map<String, String>> fetchAnotherSong();
  Future<List<Map<String, String>>> fetchPlaylistByGenreAndCategory({required String genre, required String category});
}

class DemoPlaylist extends PlaylistRepository {
  static bool isSongsNewInitialized() {
    try {
      return songsNew != null && songsNew is List && songsNew.isNotEmpty != null;
    } catch (_) {
      return false;
    }
  }
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
  /// Returns all unique categories for a given genre.
  List<String> getCategoriesForGenre(String genre) {
  print('[getCategoriesForGenre] Called with genre: $genre');
    if (!isSongsNewInitialized()) return [];
    final categories = songsNew
      .where((song) => song['genre'] == genre)
      .map((song) => song['category'] ?? '')
      .where((cat) => cat.isNotEmpty)
      .toSet()
      .map((e) => e.toString())
      .toList();
    categories.sort();
    return categories;
  }

  /// Returns playlist filtered by genre and category.
  @override
  Future<List<Map<String, String>>> fetchPlaylistByGenreAndCategory({
    required String genre,
    required String category,
  }) async {
    print('[fetchPlaylistByGenreAndCategory] Called with genre: $genre, category: $category, arguments: {genre: $genre, category: $category}');
    if (!isSongsNewInitialized() || baseURL.isEmpty) {
      print('[fetchPlaylistByGenreAndCategory] Initializing songsNew and baseURL...');
      await _initDir();
    }
    if (!isSongsNewInitialized()) {
      print('[fetchPlaylistByGenreAndCategory] ERROR: songsNew still not initialized after _initDir!');
      return [];
    }
    final filteredRawSongs = songsNew.where((song) => song['genre'] == genre && song['category'] == category).toList();
    print('[fetchPlaylistByGenreAndCategory] Found ${filteredRawSongs.length} songs for genre: $genre, category: $category');
    if (filteredRawSongs.isNotEmpty) {
      print('[fetchPlaylistByGenreAndCategory] First song title: \'${filteredRawSongs[0]['title']}\'');
    }
    return List<Map<String, String>>.from(filteredRawSongs);
  }

  Future<List<Map<String, String>>> fetchInitialPlaylist({required String genre}) async {
  //print('[fetchInitialPlaylist] Called with genre: $genre');
    //print('[fetchInitialPlaylist] Called with genre: $genre');
    // Defensive: ensure songsNew is initialized
    if (!isSongsNewInitialized() || baseURL.isEmpty) {
      //print('[fetchInitialPlaylist] Initializing songsNew and baseURL...');
      await _initDir();
    }
    if (!isSongsNewInitialized()) {
      //print('[fetchInitialPlaylist] ERROR: songsNew still not initialized after _initDir!');
      return [];
    }
    //print('[fetchInitialPlaylist] songsNew has \'${songsNew.length}\' songs.');
    // Filter songs by genre
    final List<dynamic> filteredRawSongs =
        songsNew.where((song) => song['genre'] == genre).toList();
    //print('[fetchInitialPlaylist] Found ${filteredRawSongs.length} songs for genre: $genre');
    if (filteredRawSongs.isNotEmpty) {
      //print('[fetchInitialPlaylist] First song title: \'${filteredRawSongs[0]['title']}\'');
    }

    // Convert each song from Map<String, dynamic> to Map<String, String>
    final List<Map<String, String>> playlist = filteredRawSongs.map((rawSong) {
      // Cast to the expected type
      final Map<String, dynamic> songData = rawSong as Map<String, dynamic>;

      // Convert all values to String
      final Map<String, String> songMap = songData.map(
        (key, value) => MapEntry(key, value.toString()),
      );

      // Prepend baseURL if necessary
      if (!songMap['url']!.startsWith(baseURL)) {
        songMap['url'] = baseURL + songMap['url']!;
      }

      return songMap;
    }).toList();

    return playlist;
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
