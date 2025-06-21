import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import '../models/progress_bar_state.dart';
import '../notifiers/play_button_notifier.dart';
import '../notifiers/repeat_button_notifier.dart';
import '../page_manager.dart';

class BeatScreen extends StatefulWidget {
  final String title;
  final String genre;

  BeatScreen({required this.title, required this.genre});

  @override
  _BeatScreenState createState() => _BeatScreenState();
}

class _BeatScreenState extends State<BeatScreen> {
  late final PageManager _pageManager;
  bool _beatsReady = true; // Assuming beats are ready for now
  bool _downloading = false; // Assuming not downloading for now

  @override
  void initState() {
    super.initState();
    _pageManager = PageManager();
    _pageManager.init(genre: widget.genre);
  }

  @override
  void dispose() {
    _pageManager.stop();
    _pageManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.purple,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
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
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  label: Text(
                    'Click here to Download Beats files before you can proceed...',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () {},
                ),
              Expanded(
                child: Playlist(pageManager: _pageManager),
              ),
              AudioProgressBar(pageManager: _pageManager),
              AudioControlButtons(pageManager: _pageManager),
            ],
          ),
        ),
      ),
    );
  }
}

// All the UI Widgets moved from home.dart

class Playlist extends StatelessWidget {
  final PageManager pageManager;
  const Playlist({Key? key, required this.pageManager}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<MediaItem>>(
      valueListenable: pageManager.playlistNotifier,
      builder: (context, playlist, _) {
        final genre = pageManager.playlistNotifier.value.isNotEmpty
            ? pageManager.playlistNotifier.value.first.genre ?? 'Unknown'
            : 'Unknown';
        if (playlist.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No beats found for genre: $genre',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
                SizedBox(height: 8),
                Text(
                  'Try another genre or check your beats folder.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }
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
                  child: ListTile(
                    title: Text(
                      mediaItem.title,
                      style: TextStyle(
                        color: isSelected ? Colors.green : Colors.purple.shade700,
                      ),
                    ),
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
  const AudioProgressBar({Key? key, required this.pageManager}) : super(key: key);

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
  const AudioControlButtons({Key? key, required this.pageManager}) : super(key: key);

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
  const PreviousSongButton({Key? key, required this.pageManager}) : super(key: key);

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
