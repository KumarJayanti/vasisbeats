import 'package:flutter/foundation.dart';
import 'notifiers/play_button_notifier.dart';
import 'notifiers/progress_notifier.dart';
import 'notifiers/repeat_button_notifier.dart';
import 'package:audio_service/audio_service.dart';
import 'services/playlist_repository.dart';
import 'services/service_locator.dart';
import 'models/progress_bar_state.dart';

class PageManager {
  bool _isInitialized = false;
  // Listeners: Updates going to the UI
  final currentSongTitleNotifier = ValueNotifier<String>('');
  final currentSongIdNotifier = ValueNotifier<String>('');
  final playlistNotifier = ValueNotifier<List<MediaItem>>([]);
  final ProgressNotifier _progressNotifier = ProgressNotifier();

  // Private notifiers
  final PlayButtonNotifier _playButtonNotifier = PlayButtonNotifier();
  final RepeatButtonNotifier _repeatButtonNotifier = RepeatButtonNotifier();
  final ValueNotifier<bool> _isFirstSongNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isLastSongNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isShuffleModeEnabledNotifier =
      ValueNotifier<bool>(false);

  // Getters to expose notifiers as ValueListenable
  ValueListenable<ButtonState> get playButtonNotifier => _playButtonNotifier;
  ValueListenable<RepeatState> get repeatButtonNotifier =>
      _repeatButtonNotifier;
  ValueListenable<bool> get isFirstSongNotifier => _isFirstSongNotifier;
  ValueListenable<bool> get isLastSongNotifier => _isLastSongNotifier;
  ValueListenable<bool> get isShuffleModeEnabledNotifier =>
      _isShuffleModeEnabledNotifier;
  ValueListenable<ProgressBarState> get progressNotifier => _progressNotifier;

  late AudioHandler _audioHandler;

  // Events: Calls coming from the UI
  Future<void> init(
      {required String genre,
      String? category,
      bool loadPlaylist = false}) async {
    _audioHandler = await getIt<AudioHandler>();
    if (loadPlaylist) {
      await _loadPlaylist(genre: genre, category: category);
    }
    _listenToChangesInPlaylist();
    _listenToPlaybackState();
    _listenToCurrentPosition();
    _listenToBufferedPosition();
    _listenToTotalDuration();
    _listenToChangesInSong();
    _isInitialized = true;
  }

  /// Loads a playlist from an in-memory list of song maps (used for category filtering)
  /// Call init() before using this method!
  Future<void> loadFromMemory(List<Map<String, String>> beats) async {
    final mediaItems = beats
        .map((song) => MediaItem(
              id: song['id'] ?? '',
              album: song['album'] ?? '',
              title: song['title'] ?? '',
              extras: {'url': song['url']},
              genre: song['genre'] ?? '',
            ))
        .toList();
    // Clear previous queue if needed
    playlistNotifier.value = [];
    currentSongTitleNotifier.value = '';
    currentSongIdNotifier.value = '';

    //print(
    //    '[PageManager::loadFromMemory] Clearing queue before adding new category songs');
    await _audioHandler.customAction('clearQueue');
    int size = await _audioHandler.queue.value.length;
    //print('[PageManager::loadFromMemory] Queue size after clear: $size');
    if (mediaItems.isNotEmpty) {
      _audioHandler.addQueueItems(mediaItems);
    }
    //print('[PageManager::loadFromMemory] Added ${mediaItems.length} songs to queue');
    size = await _audioHandler.queue.value.length;
    //print('[PageManager::loadFromMemory] Queue size after Adding new Category songs: $size');
  }

  Future<void> _loadPlaylist({required String genre, String? category}) async {
    // Always reset play button state to stopped when switching genres
    //somehow when switchings genres this code is not in picture at all
    _playButtonNotifier.setState(ButtonState.paused);
    playlistNotifier.value = [];
    currentSongTitleNotifier.value = '';
    currentSongIdNotifier.value = '';
    //print('[PageManager] Calling clearQueue on handler: ${_audioHandler.runtimeType}');
    await _audioHandler
        .customAction('clearQueue'); // force clear queue and player
    //print('[PageManager] After reset: playlistNotifier.value.length = ${playlistNotifier.value.length}');
    //print('[PageManager] AudioHandler queue.length = ${_audioHandler.queue.value.length}');
    //print('[PageManager] Play button state = ${_playButtonNotifier.value}');

    final songRepository = getIt<PlaylistRepository>();
    final playlist = category != null
        ? await songRepository.fetchPlaylistByGenreAndCategory(
            genre: genre, category: category)
        : await songRepository.fetchInitialPlaylist(genre: genre);
    final mediaItems = playlist
        .map((song) => MediaItem(
              id: song['id'] ?? '',
              album: song['album'] ?? '',
              title: song['title'] ?? '',
              extras: {'url': song['url']},
              genre: song['genre'] ?? '',
            ))
        .toList();
    if (mediaItems.isEmpty) {
      // Aggressive reset: clear UI and audio handler state
      print('[PageManager] No media items for this genre. Clearing state.');
      return;
    }
    _audioHandler.addQueueItems(mediaItems);
  }

  void _listenToChangesInPlaylist() {
    _audioHandler.queue.listen((playlist) {
      //print('[PageManager::_listenToChangesInPlaylist] called. Playlist length: ${playlist.length}');
      if (playlist.isEmpty) {
        //print('[PageManager::_listenToChangesInPlaylist] Playlist is empty. Clearing playlistNotifier.');
        playlistNotifier.value = [];
        currentSongTitleNotifier.value = '';
        currentSongIdNotifier.value = '';
      } else {
        final newList = playlist.toList();
        //print('[PageManager::_listenToChangesInPlaylist] Setting playlistNotifier.value to list of length: ${newList.length}');
        playlistNotifier.value = newList;
      }
      _updateSkipButtons();
    });
  }

  void _listenToPlaybackState() {
    _audioHandler.playbackState.listen((playbackState) {
      final isPlaying = playbackState.playing;
      final processingState = playbackState.processingState;
      if (processingState == AudioProcessingState.loading ||
          processingState == AudioProcessingState.buffering) {
        _playButtonNotifier.setState(ButtonState.loading);
      } else if (!isPlaying) {
        _playButtonNotifier.setState(ButtonState.paused);
      } else if (processingState != AudioProcessingState.completed) {
        _playButtonNotifier.setState(ButtonState.playing);
      } else {
        _audioHandler.seek(Duration.zero);
        _audioHandler.pause();
      }
    });
  }

  void _listenToCurrentPosition() {
    _audioHandler.playbackState.listen((state) {
      final position = state.updatePosition;
      if (position.inMilliseconds > 0) {
        _progressNotifier.update(current: position);
      }
    });
  }

  void _listenToBufferedPosition() {
    _audioHandler.playbackState.listen((state) {
      _progressNotifier.update(buffered: state.bufferedPosition);
    });
  }

  void _listenToTotalDuration() {
    _audioHandler.mediaItem.listen((item) {
      if (item?.duration != null) {
        _progressNotifier.update(total: item!.duration!);
      }
    });
  }

  void _listenToChangesInSong() {
    _audioHandler.mediaItem.listen((mediaItem) {
      currentSongTitleNotifier.value = mediaItem?.title ?? '';
      currentSongIdNotifier.value = mediaItem?.id ?? '0';
      //we want to update playlistNotifier.value at this point
      _listenToChangesInPlaylist();
      _updateSkipButtons();
    });
  }

  void _updateSkipButtons() {
    final mediaItem = _audioHandler.mediaItem.value;
    final playlist = _audioHandler.queue.value;
    if (playlist.isEmpty || mediaItem == null) {
      _isFirstSongNotifier.value = true;
      _isLastSongNotifier.value = true;
    } else {
      _isFirstSongNotifier.value = playlist.first == mediaItem;
      _isLastSongNotifier.value = playlist.last == mediaItem;
    }
  }

  Future<void> seekToSong(int selectedIndex) async {
    //print("_seekToSong: selected index : ${selectedIndex}");
    await _audioHandler.skipToQueueItem(selectedIndex);
    //_listenToChangesInPlaylist();
  }

  void play() => _audioHandler.play();
  void pause() => _audioHandler.pause();

  void seek(Duration? position) {
    if (position != null) {
      _audioHandler.seek(position);
    }
  }

  void previous() => _audioHandler.skipToPrevious();
  void next() => _audioHandler.skipToNext();

  void toggleRepeat() {
    _repeatButtonNotifier.nextState();
    final repeatMode = _repeatButtonNotifier.value;
    switch (repeatMode) {
      case RepeatState.off:
        _audioHandler.setRepeatMode(AudioServiceRepeatMode.none);
        break;
      case RepeatState.repeatSong:
        _audioHandler.setRepeatMode(AudioServiceRepeatMode.one);
        break;
      case RepeatState.repeatPlaylist:
        _audioHandler.setRepeatMode(AudioServiceRepeatMode.all);
        break;
    }
  }

  void shuffle() {
    final enable = !_isShuffleModeEnabledNotifier.value;
    _isShuffleModeEnabledNotifier.value = enable;
    if (enable) {
      _audioHandler.setShuffleMode(AudioServiceShuffleMode.all);
    } else {
      _audioHandler.setShuffleMode(AudioServiceShuffleMode.none);
    }
  }

  Future<void> add() async {
    final songRepository = getIt<PlaylistRepository>();
    final song = await songRepository.fetchAnotherSong();
    final mediaItem = MediaItem(
      id: song['id'] ?? '',
      album: song['album'] ?? '',
      title: song['title'] ?? '',
      extras: {'url': song['url']},
      genre: song['genre'] ?? '',
    );
    int size = await _audioHandler.queue.value.length;

    /*
    if (size >= 6) {
      await _audioHandler.removeQueueItemAt(0);
      MediaItem tmp = _audioHandler.queue.value.elementAt(0);
      currentSongTitleNotifier.value = tmp?.title ?? '';
    }*/
    //print(mediaItem);
    _audioHandler.addQueueItem(mediaItem);
  }

  void remove() {
    final lastIndex = _audioHandler.queue.value.length - 1;
    if (lastIndex < 0) return;
    _audioHandler.removeQueueItemAt(lastIndex);
  }

  void stop() {
    if (!_isInitialized) return;
    _audioHandler.stop();
  }

  void dispose() {
    _isInitialized = false;
    // Removed dispose call to keep player alive
  }
}
