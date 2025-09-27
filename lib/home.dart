import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:audio_service/audio_service.dart';
import 'package:item_selector/item_selector.dart';
import 'package:flutter/foundation.dart';
import 'models/progress_bar_state.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

import 'page_manager.dart';
import 'services/service_locator.dart';
import 'screens/beat_screens.dart';
import 'notifiers/play_button_notifier.dart';
import 'notifiers/repeat_button_notifier.dart';

export 'notifiers/play_button_notifier.dart';
export 'notifiers/progress_notifier.dart';
export 'notifiers/repeat_button_notifier.dart';
export 'page_manager.dart';
export 'services/service_locator.dart';
export 'screens/beat_screens.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _downloading = false;
  bool _beatsReady = true;

  void _showRatingDialog(BuildContext context) {
    double rating = 3.0;
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Rate Our App'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Optional feedback',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text('Submit'),
                  onPressed: () async {
                    const playStoreUrl = 'https://play.google.com/store/apps/details?id=dev.suragch.flutter_audio_service_demo';
                    const appStoreUrl = 'https://apps.apple.com/app/id1624246378';
                    const macAppStoreUrl = 'https://apps.apple.com/app/id1625800928';
                    final inAppReview = InAppReview.instance;
                    bool didRequest = false;
                    try {
                      if (await inAppReview.isAvailable()) {
                        await inAppReview.requestReview();
                        didRequest = true;
                      } else {
                        // Fallback by platform
                        if (Theme.of(context).platform == TargetPlatform.android) {
                          final uri = Uri.parse(playStoreUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        } else if (Theme.of(context).platform == TargetPlatform.iOS) {
                          final uri = Uri.parse(appStoreUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        } else if (Theme.of(context).platform == TargetPlatform.macOS) {
                          final uri = Uri.parse(macAppStoreUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        }
                      }
                    } catch (e) {
                      // Fallback in case of error
                      if (Theme.of(context).platform == TargetPlatform.android) {
                        final uri = Uri.parse(playStoreUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
                        final uri = Uri.parse(appStoreUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      } else if (Theme.of(context).platform == TargetPlatform.macOS) {
                        final uri = Uri.parse(macAppStoreUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      }
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    //getIt<PageManager>().init();
  }

  @override
  void dispose() {
    getIt<PageManager>().dispose();
    super.dispose();
  }

  bool get _isPaidUser {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.emailVerified;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.purple,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text('Home'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.star_rate),
            tooltip: 'Rate Us',
            onPressed: () => _showRatingDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("images/vasis.jpeg"), fit: BoxFit.cover)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              !_beatsReady && !_downloading
                  ? TextButton.icon(
                      icon: Icon(
                        Icons.file_download,
                        color: Colors.red,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      label: Text(
                          'Click here to Download Beats files before you can proceed...',
                          style: TextStyle(color: Colors.red)),
                      onPressed: _beatsReady ? null : () {})
                  : Container(),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  children: [
                    _buildNavigationItem(
                      imageAsset: 'images/do_taal.png',
                      label: 'Do Taal Slow',
                      onTap: () => _navigateToScreen(context, DoTaalSlowScreen()),
                      isPaidOnly: true,
                    ),
                    _buildNavigationItem(
                      icon: Icons.music_note,
                      imageAsset: 'images/do_taal.png',
                      label: 'Do Taal Fast',
                      onTap: () => _navigateToScreen(context, DoTaalFastScreen()),
                      isPaidOnly: true,
                    ),
                    _buildNavigationItem(
                      icon: Icons.music_note,
                      imageAsset: 'images/teen_taal.png',
                      label: 'Teen Taal Slow',
                      onTap: () => _navigateToScreen(context, TeenTaalSlowScreen()),
                    ),
                    _buildNavigationItem(
                      icon: Icons.music_note,
                      imageAsset: 'images/teen_taal.png',
                      label: 'Teen Taal Fast',
                      onTap: () => _navigateToScreen(context, TeenTaalFastScreen()),
                      isPaidOnly: true,
                    ),
                    _buildNavigationItem(
                      icon: Icons.music_note,
                      imageAsset: 'images/changing.png',
                      label: 'Changing Speeds',
                      onTap: () => _navigateToScreen(context, ChangingSpeedsScreen()),
                      isPaidOnly: true,
                    ),
                    _buildNavigationItem(
                      icon: Icons.more_horiz, // golden icon for Others
                      label: 'Future',
                      onTap: () => _navigateToScreen(context, BeatScreen(title: 'Others', genre: 'others')),
                      isPaidOnly: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem({
    IconData? icon,
    String? imageAsset,
    required String label,
    required VoidCallback onTap,
    bool isPaidOnly = false,
  }) {
    bool isPaid = _isPaidUser;
    
    return GestureDetector(
      onTap: isPaid || !isPaidOnly ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.8),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageAsset != null)
              Image.asset(
                imageAsset,
                width: 40,
                height: 40,
              )
            else if (icon != null)
              Icon(
                icon,
                size: 40,
                color: label == 'Future' ? Colors.amber : Colors.white,
              ),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isPaidOnly) ...[
              SizedBox(height: 5),
              Text(
                'Available for Paid Users',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class Playlist extends StatefulWidget {
  Playlist({Key? key}) : super(key: key);

  @override
  _PlayListState createState() => _PlayListState();
}

class _PlayListState extends State<Playlist> {
  int _selectedIndex_k = 0;
  int _selectedIndex_km = 0;
  int _selectedIndex_kmt = 0;
  late ValueNotifier<String> _currentSongId;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final pageManager = getIt<PageManager>();
    _currentSongId = pageManager.currentSongIdNotifier;
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
   //_currentSongId.dispose();
    super.dispose();
  }

  List<dynamic> getItemsByGenre(String genre, List<dynamic> items) {
    //print(items);
    bool checkboxValue = false;
    bool y = checkboxValue != null && checkboxValue == true;
    return items.where((item) => item.genre == genre).toList();
  }



  Widget _buildTabListView(String genre, int selectedIndex, Function(int) onIndexChanged) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<List<MediaItem>>(
      valueListenable: pageManager.playlistNotifier,
      builder: (context, playlistTitles, _) {
        final genreSongs = getItemsByGenre(genre, playlistTitles);
        return Scrollbar(
          controller: _scrollController,
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            controller: _scrollController,
            itemCount: genreSongs.length,
            itemBuilder: (BuildContext context, int index) {
              final song = genreSongs[index];
              final isSelected = _currentSongId.value == song.id;
              
              return Card(
                elevation: isSelected ? 2 : 10,
                margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                color: isSelected ? Colors.green.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
                child: InkWell(
                  onTap: () {
                    final songIndex = playlistTitles.indexWhere((item) => item.id == song.id);
                    if (songIndex != -1) {
                      pageManager.seekToSong(songIndex);
                      onIndexChanged(songIndex);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: AssetImage('images/$genre.png'),
                          radius: isSelected ? 20 : 9,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              color: isSelected ? Colors.green : Colors.purple.shade700,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.speaker, color: Colors.green.shade700, size: 20)
                        else
                          Icon(Icons.queue_music_rounded, color: Colors.purple.shade700, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return Expanded(
      child: ValueListenableBuilder<List<MediaItem>>(
        valueListenable: pageManager.playlistNotifier,
        builder: (context, playlistTitles, _) {
          return DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                centerTitle: true,
                title: CircleAvatar(
                  backgroundImage: AssetImage('images/appicon.png'),
                  radius: 24,
                ),
                bottom: TabBar(
                  indicator: BoxDecoration(
                    /*color: Colors.purple
                  .shade300, */
                    // Set the color of the selected tab indicator
                    image: DecorationImage(
                      image: AssetImage('images/vasis.jpeg'),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(
                        10.0), // Set the border radius of the selected tab indicator
                  ),
                  tabs: [
                    Tab(
                      child: Image.asset(
                        'images/k.png',
                        width: 64,
                        height: 64,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    Tab(
                      child: Image.asset(
                        'images/km.png',
                        width: 64,
                        height: 64,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    Tab(
                      child: Image.asset(
                        'images/kmt.png',
                        width: 64,
                        height: 64,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ],
                ),
              ),
              body: Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("images/vasis.jpeg"),
                        fit: BoxFit.cover)),
                child: TabBarView(
                  children: [
                    _buildTabListView('K', _selectedIndex_k, (index) => _selectedIndex_k = index),
                    _buildTabListView('KM', _selectedIndex_km, (index) => _selectedIndex_km = index),
                    _buildTabListView('KMT', _selectedIndex_kmt, (index) => _selectedIndex_kmt = index),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


class AudioProgressBar extends StatelessWidget {
  const AudioProgressBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<ProgressBarState>(
      valueListenable: pageManager.progressNotifier,
      builder: (_, value, __) {
        return ProgressBar(
          progress: value.current,
          buffered: value.buffered,
          total: value.total,
          onSeek: (duration) => pageManager.seek(duration),
        );
      },
    );
  }
}

class AudioControlButtons extends StatelessWidget {
  const AudioControlButtons({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          RepeatButton(),
          PreviousSongButton(),
          PlayButton(),
          NextSongButton(),
          ShuffleButton(),
        ],
      ),
    );
  }
}

class RepeatButton extends StatelessWidget {
  const RepeatButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<RepeatState>(
      valueListenable: pageManager.repeatButtonNotifier,
      builder: (context, value, child) {
        return IconButton(
          icon: Icon(
            value == RepeatState.repeatSong ? Icons.repeat_one : Icons.repeat,
            color: Colors.white,
          ),
          onPressed: pageManager.toggleRepeat,
        );
      },
    );
  }
}

class PreviousSongButton extends StatelessWidget {
  const PreviousSongButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
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
  const PlayButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<ButtonState>(
      valueListenable: pageManager.playButtonNotifier,
      builder: (_, value, __) {
        switch (value) {
          case ButtonState.loading:
            return Container(
              margin: EdgeInsets.all(8.0),
              width: 32.0,
              height: 32.0,
              child: CircularProgressIndicator(),
            );
          case ButtonState.paused:
            return IconButton(
              icon: Icon(Icons.play_arrow, color: Colors.white),
              iconSize: 32.0,
              onPressed: pageManager.play,
            );
          case ButtonState.playing:
            return IconButton(
              icon: Icon(Icons.pause, color: Colors.white),
              iconSize: 32.0,
              onPressed: pageManager.pause,
            );
        }
      },
    );
  }
}

class NextSongButton extends StatelessWidget {
  const NextSongButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
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
  const ShuffleButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<bool>(
      valueListenable: pageManager.isShuffleModeEnabledNotifier,
      builder: (context, isEnabled, child) {
        return IconButton(
          icon: (isEnabled)
              ? Icon(Icons.shuffle, color: Colors.white)
              : Icon(Icons.shuffle, color: Colors.white),
          onPressed: pageManager.shuffle,
        );
      },
    );
  }
}
