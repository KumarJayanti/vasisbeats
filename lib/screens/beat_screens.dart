import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import '../models/progress_bar_state.dart';
import '../notifiers/play_button_notifier.dart';
import '../notifiers/repeat_button_notifier.dart';
import '../page_manager.dart';

import '../services/service_locator.dart';
import '../services/playlist_repository.dart';

class BeatScreen extends StatefulWidget {
  final String title;
  final String genre;

  BeatScreen({required this.title, required this.genre});

  @override
  _BeatScreenState createState() => _BeatScreenState();
}

class _BeatScreenState extends State<BeatScreen>
    with SingleTickerProviderStateMixin {
  late final PageManager _pageManager;
  List<String> _categories = [];
  late TabController _tabController;
  String? _selectedCategory;
  bool _beatsReady = true;
  bool _downloading = false;
  List<Map<String, String>>? _allBeatsForGenre;

  @override
  void initState() {
    super.initState();
    _pageManager = PageManager();
    _initGenreData();
  }

  Future<void> _initGenreData() async {
    final repo = getIt<PlaylistRepository>() as dynamic;
    // Fetch all beats for this genre once
    _allBeatsForGenre = await repo.fetchInitialPlaylist(genre: widget.genre == 'future' ? 'future' : widget.genre);
    // Dynamically extract unique categories from the fetched beats
    _categories = _allBeatsForGenre != null
        ? _allBeatsForGenre!
            .map((song) => song['category'] ?? '')
            .where((cat) => cat.isNotEmpty)
            .toSet()
            .toList()
        : [];
    _categories.sort();
    // Recreate TabController with new categories
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Set default category
    _selectedCategory = _categories.isNotEmpty ? _categories[0] : null;
    // Ensure PageManager is initialized for this genre, but do NOT load a playlist yet
    await _pageManager.init(genre: widget.genre == 'future' ? 'future' : widget.genre, loadPlaylist: false);
    // Now load only the selected category's beats
    if (_selectedCategory != null) {
      await _loadCategoryBeats(_selectedCategory!);
    }
    setState(() {});
  }

  Future<void> _onTabChanged() async {
    if (_tabController.indexIsChanging) return;
    final newCategory = _categories[_tabController.index];
    if (newCategory == _selectedCategory) return;
    _selectedCategory = newCategory;
    _pageManager.stop();
    await _loadCategoryBeats(_selectedCategory!);
    setState(() {});
  }

  Future<void> _loadCategoryBeats(String category) async {
    if (_allBeatsForGenre == null) return;
    final beats = _allBeatsForGenre!
        .where((song) => song['category'] == category)
        .toList();
   //print beats length and the song names  
    //print('[_loadCategoryBeats] beats length: ${beats.length}');
    //beats.forEach((song) => print('[_loadCategoryBeats] song name: ${song['title']}'));
    await _pageManager.loadFromMemory(beats);
    setState(() {});
  }

  String getCategoryImage(String category) {
    switch (category) {
      case 'K':
        return 'images/k.png';
      case 'KM':
        return 'images/km.png';
      case 'KMT':
        return 'images/kmt.png';
      case 'Short':
        return 'images/short.png';
      case 'Long':
        return 'images/long.png';
      default:
        return 'images/appicon.png'; // fallback image
    }
  }
  String getCategoryAltText(String category) {
  switch (category) {
    case 'K':
      return 'K - Kartal Only';
    case 'KM':
      return 'KM - Kartal & Mridangam';
    case 'KMT':
      return 'KMT - Kartal & Mridangam  Tehai';
    case 'Short':
      return 'Changing Speed - Short Beats';
    case 'Long':
      return 'Changing Speed - Long Beats';
    default:
      return 'Category';
  }
}

  @override
  void dispose() {
    _tabController.dispose();
    _pageManager.stop();
    _pageManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //print('[BeatScreen] build() called. _selectedCategory: \\$_selectedCategory');
    if (_categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.purple,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text('No categories found for this genre.'),
        ),
      );
    }
    return DefaultTabController(
      length: _categories.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.purple,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(60),
            child: Container(
              width: double.infinity,
              height: 60,
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                indicator: BoxDecoration(
                  color: Colors.white.withOpacity(0.3), // Semi-transparent white for selected tab
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                tabs: _categories.map((cat) => Tab(
                  icon: Image.asset(
                    getCategoryImage(cat),
                    width: 40, // slightly larger
                    height: 40,
                    semanticLabel: getCategoryAltText(cat),
                  ),
                )).toList(),
              ),
            ),
          ),
        ),
        body: TabBarView(
           controller: _tabController,
          children: _categories.map((cat) {
            final beats = _allBeatsForGenre == null
                ? []
                : _allBeatsForGenre!
                    .where((song) => song['category'] == cat)
                    .toList();
            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("images/vasis.jpeg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    if (!_beatsReady && !_downloading)
                      TextButton.icon(
                        icon: Icon(Icons.file_download, color: Colors.red),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.white),
                        label: Text(
                          'Click here to Download Beats files before you can proceed...',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () {},
                      ),
                    Expanded(
                      child: Playlist(
                        // When isCurrent, pass only the filtered beats for the selected category
                        pageManager: _pageManager,
                        beats: _selectedCategory == cat
                            ? List<Map<String, String>>.from(beats)
                            : const [],
                        isCurrent: _selectedCategory == cat,
                      ),
                    ),
                    AudioProgressBar(pageManager: _pageManager),
                    AudioControlButtons(pageManager: _pageManager),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// All the UI Widgets moved from home.dart

class Playlist extends StatelessWidget {
  final PageManager pageManager;
  final List<Map<String, String>> beats;
  final bool isCurrent;
  const Playlist({Key? key, required this.pageManager, required this.beats, required this.isCurrent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (beats.isEmpty) {
      return Center(
        child: Text(
          'No beats found for this category',
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      );
    }
    // Only show the queue and allow playback if this is the current tab
    if (!isCurrent) {
      return Center(child: Text('Switch to this tab to play beats.'));
    }
    //print('[Playlist] ValueListenableBuilder is building. playlistNotifier.value.length: ${pageManager.playlistNotifier.value.length}');
  return ValueListenableBuilder<List<MediaItem>>(
    valueListenable: pageManager.playlistNotifier,
    builder: (context, playlist, _) {
        //print('[Playlist] UI ListView.builder received playlist of length: ${playlist.length}');
      return ListView.builder(
        itemCount: playlist.length,
          itemBuilder: (context, index) {
            final mediaItem = playlist[index];
            return ValueListenableBuilder<String>(
              valueListenable: pageManager.currentSongIdNotifier,
              builder: (context, currentSongId, __) {
                final isSelected = mediaItem.id == currentSongId;
                return Card(
                  elevation: isSelected ? 2 : 10,
                  color: isSelected ? Colors.green[50] : Colors.white,
                  child: ListTile(
                    title: Text(
                      mediaItem.title,
                      style: TextStyle(
                        color: isSelected ? Colors.green : Colors.purple.shade700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(mediaItem.album ?? ''),
                    trailing: isSelected
                        ? Icon(Icons.speaker, color: Colors.green.shade700)
                        : Icon(Icons.queue_music_rounded, color: Colors.purple.shade700),
                    onTap: () {
                      pageManager.seekToSong(index);
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}


class AudioProgressBar extends StatelessWidget {
  final PageManager pageManager;
  const AudioProgressBar({Key? key, required this.pageManager})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProgressBarState>(
      valueListenable: pageManager.progressNotifier,
      builder: (_, value, __) {
        return ProgressBar(
          progress: value.current,
          buffered: value.buffered,
          total: value.total,
          onSeek: pageManager.seek,
        );
      },
    );
  }
}

class AudioControlButtons extends StatelessWidget {
  final PageManager pageManager;
  const AudioControlButtons({Key? key, required this.pageManager})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          RepeatButton(pageManager: pageManager),
          PreviousSongButton(pageManager: pageManager),
          PlayButton(pageManager: pageManager),
          NextSongButton(pageManager: pageManager),
          ShuffleButton(pageManager: pageManager),
        ],
      ),
    );
  }
}

class RepeatButton extends StatelessWidget {
  final PageManager pageManager;
  const RepeatButton({Key? key, required this.pageManager}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RepeatState>(
      valueListenable: pageManager.repeatButtonNotifier,
      builder: (context, value, child) {
        IconData icon;
        switch (value) {
          case RepeatState.off:
            icon = Icons.repeat;
            break;
          case RepeatState.repeatSong:
            icon = Icons.repeat_one;
            break;
          case RepeatState.repeatPlaylist:
            icon = Icons.repeat;
            break;
        }
        return IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: pageManager.toggleRepeat,
        );
      },
    );
  }
}

class PreviousSongButton extends StatelessWidget {
  final PageManager pageManager;
  const PreviousSongButton({Key? key, required this.pageManager})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: pageManager.isFirstSongNotifier,
      builder: (_, isFirst, __) {
        return IconButton(
          icon: Icon(Icons.skip_previous, color: Colors.white),
          onPressed: (isFirst) ? null : pageManager.previous,
        );
      },
    );
  }
}

class PlayButton extends StatelessWidget {
  final PageManager pageManager;
  const PlayButton({Key? key, required this.pageManager}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ButtonState>(
      valueListenable: pageManager.playButtonNotifier,
      builder: (_, value, __) {
        switch (value) {
          case ButtonState.loading:
            return Container(
              margin: const EdgeInsets.all(8.0),
              width: 32.0,
              height: 32.0,
              child: const CircularProgressIndicator(),
            );
          case ButtonState.paused:
            return IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              iconSize: 32.0,
              onPressed: pageManager.play,
            );
          case ButtonState.playing:
            return IconButton(
              icon: const Icon(Icons.pause, color: Colors.white),
              iconSize: 32.0,
              onPressed: pageManager.pause,
            );
        }
      },
    );
  }
}

class NextSongButton extends StatelessWidget {
  final PageManager pageManager;
  const NextSongButton({Key? key, required this.pageManager}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: pageManager.isLastSongNotifier,
      builder: (_, isLast, __) {
        return IconButton(
          icon: Icon(Icons.skip_next, color: Colors.white),
          onPressed: (isLast) ? null : pageManager.next,
        );
      },
    );
  }
}

class ShuffleButton extends StatelessWidget {
  final PageManager pageManager;
  const ShuffleButton({Key? key, required this.pageManager}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: pageManager.isShuffleModeEnabledNotifier,
      builder: (context, isEnabled, child) {
        return IconButton(
          icon: (isEnabled)
              ? const Icon(Icons.shuffle, color: Colors.yellow)
              : const Icon(Icons.shuffle, color: Colors.white),
          onPressed: pageManager.shuffle,
        );
      },
    );
  }
}

// The screens that navigate to BeatScreen
class DoTaalSlowScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BeatScreen(title: 'Do Taal Slow', genre: 'do_taal_slow');
  }
}

class DoTaalFastScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BeatScreen(title: 'Do Taal Fast', genre: 'do_taal_fast');
  }
}

class TeenTaalSlowScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BeatScreen(title: 'Teen Taal Slow', genre: 'teen_taal_slow');
  }
}

class TeenTaalFastScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BeatScreen(title: 'Teen Taal Fast', genre: 'teen_taal_fast');
  }
}

class ChangingSpeedsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BeatScreen(title: 'Changing Speeds', genre: 'changing_speeds');
  }
}
