import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'notifiers/play_button_notifier.dart';
import 'notifiers/progress_notifier.dart';
import 'notifiers/repeat_button_notifier.dart';
import 'page_manager.dart';
import 'services/service_locator.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:item_selector/item_selector.dart';
import 'package:audio_service/audio_service.dart';

import 'package:flutter/foundation.dart';


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _downloading = false;
  bool _beatsReady = true;
  String _dir = "";

  String _text = 'SignUp';
  final Uri _url = Uri.parse('https://kirtanforlife.com/');

  @override
  void initState() {
    getIt<PageManager>().init();
    _downloading = false;
    super.initState();
  }

  @override
  void dispose() {
    getIt<PageManager>().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
              /*CurrentSongTitle(),*/
              Playlist(),
              /*AddRemoveSongButtons(),*/
              AudioProgressBar(),
              AudioControlButtons(),
            ],
          ),
        ),
      ),
    );
  }

  _launchURL() async {
    if (await canLaunchUrl(_url)) {
      await launchUrl(_url);
    } else {
      throw 'Could not launch $_url';
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
    _currentSongId.dispose();
    super.dispose();
  }

  List<dynamic> getItemsByGenre(String genre, List<dynamic> items) {
    //print(items);
    bool checkboxValue = false;
    bool y = checkboxValue != null && checkboxValue == true;
    return items.where((item) => item.genre == genre).toList();
  }

  Widget buildListView(
      PageManager pageManager,
      String genre,
      List<dynamic> playlistTitles,
      int selectedIndex,
      Function(int) onSongSelected) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Scrollbar(
          controller: _scrollController,
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            controller: _scrollController,
            itemCount: getItemsByGenre(genre, playlistTitles).length,
            itemBuilder: (BuildContext context, int index) {
              int inferredIndex = int.parse(_currentSongId.value);
              if (inferredIndex != selectedIndex) {
                selectedIndex = inferredIndex;
              }
              return ItemSelectionController(
                child: ItemSelectionBuilder(
                  index: int.parse(
                      getItemsByGenre(genre, playlistTitles)[index].id),
                  builder: (context, index, selected) {
                    return Card(
                      elevation: selected ? 2 : 10,
                      child: ListTile(
                        onTap: () {
                          pageManager.seekToSong(index);
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                        onLongPress: () {
                          pageManager.seekToSong(index);
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                        title: selectedIndex == index
                            ? Text(
                                '${playlistTitles[index].title}',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.green),
                              )
                            : Text(
                                '${playlistTitles[index].title}',
                                style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.purple.shade700),
                              ),
                        trailing: selectedIndex == index
                            ? Icon(Icons.speaker, color: Colors.green.shade700)
                            : Icon(Icons.queue_music_rounded,
                                color: Colors.purple.shade700),
                        leading: CircleAvatar(
                          backgroundImage: AssetImage('images/$genre.png'),
                          radius: selectedIndex == index ? 15 : 9,
                        ),
                        tileColor: selectedIndex == index
                            ? Colors.green.withOpacity(0.1)
                            : Colors.purple.withOpacity(0.1),
                      ),
                    );
                  },
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
                    Scrollbar(
                      controller: _scrollController,
                      child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        controller: _scrollController,
                        itemCount: getItemsByGenre('K', playlistTitles).length,
                        itemBuilder: (BuildContext context, int index) {
                          //refactor this code into a separate function with parameters
                          //as it is used 3 times
                          return StatefulBuilder(builder:
                              (BuildContext context, StateSetter setState) {
                            return ItemSelectionController(
                                child: ItemSelectionBuilder(
                                    index: int.parse(getItemsByGenre(
                                            'K', playlistTitles)[index]
                                        .id),
                                    builder: (context, index, selected) {
                                      //if there is a change in _currentSongId then update _selectedIndex
                                      int inferredIndex =
                                          int.parse(_currentSongId.value);
                                      if (inferredIndex != _selectedIndex_k) {
                                        _selectedIndex_k = inferredIndex;
                                      }
                                      return Card(
                                        elevation: selected ? 2 : 10,
                                        child: ListTile(
                                            onTap: () => {
                                                  pageManager.seekToSong(index),
                                                  setState(() {
                                                    _selectedIndex_k = index;
                                                  }),
                                                },
                                            onLongPress: () {
                                              pageManager.seekToSong(index);
                                              setState(() {
                                                _selectedIndex_k = index;
                                              });
                                            },
                                            title: _selectedIndex_k == index
                                                ? Text(
                                                    '${playlistTitles[index].title}',
                                                    style: TextStyle(
                                                        fontSize: 15,
                                                        color: Colors.green),
                                                  )
                                                : Text(
                                                    '${playlistTitles[index].title}',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      color: Colors
                                                          .purple.shade700,
                                                    ),
                                                  ),
                                            trailing: _selectedIndex_k == index
                                                ? Icon(Icons.speaker,
                                                    color:
                                                        Colors.green.shade700)
                                                : Icon(
                                                    Icons.queue_music_rounded,
                                                    color:
                                                        Colors.purple.shade700),
                                            leading: CircleAvatar(
                                              backgroundImage:
                                                  AssetImage('images/k.png'),
                                              radius: _selectedIndex_k == index
                                                  ? 20
                                                  : 9,
                                            ),
                                            tileColor: _selectedIndex_k == index
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.purple
                                                    .withOpacity(0.1)),
                                      );
                                    }));
                          });
                        },
                      ),
                    ),
                    Scrollbar(
                      controller: _scrollController,
                      child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        controller: _scrollController,
                        itemCount: getItemsByGenre('KM', playlistTitles).length,
                        itemBuilder: (BuildContext context, int index) {
                          return StatefulBuilder(builder:
                              (BuildContext context, StateSetter setState) {
                            return ItemSelectionController(
                                child: ItemSelectionBuilder(
                                    index: int.parse(getItemsByGenre(
                                            'KM', playlistTitles)[index]
                                        .id),
                                    builder: (context, index, selected) {
                                      //if there is a change in _currentSongId then update _selectedIndex
                                      int inferredIndex =
                                          int.parse(_currentSongId.value);
                                      if (inferredIndex != _selectedIndex_km) {
                                        _selectedIndex_km = inferredIndex;
                                      }
                                      return Card(
                                        elevation: selected ? 2 : 10,
                                        child: ListTile(
                                            onTap: () => {
                                                  pageManager.seekToSong(index),
                                                  setState(() {
                                                    _selectedIndex_km = index;
                                                  }),
                                                },
                                            onLongPress: () {
                                              pageManager.seekToSong(index);
                                              setState(() {
                                                _selectedIndex_km = index;
                                              });
                                            },
                                            title: _selectedIndex_km == index
                                                ? Text(
                                                    '${playlistTitles[index].title}',
                                                    style: TextStyle(
                                                        fontSize: 15,
                                                        color: Colors.green),
                                                  )
                                                : Text(
                                                    '${playlistTitles[index].title}',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      color: Colors
                                                          .purple.shade700,
                                                    ),
                                                  ),
                                            trailing: _selectedIndex_km == index
                                                ? Icon(Icons.speaker,
                                                    color:
                                                        Colors.green.shade700)
                                                : Icon(
                                                    Icons.queue_music_rounded,
                                                    color:
                                                        Colors.purple.shade700),
                                            leading: CircleAvatar(
                                              backgroundImage:
                                                  AssetImage('images/km.png'),
                                              radius: _selectedIndex_km == index
                                                  ? 20
                                                  : 9,
                                            ),
                                            tileColor: _selectedIndex_km ==
                                                    index
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.purple
                                                    .withOpacity(0.1)),
                                      );
                                    }));
                          });
                        },
                      ),
                    ),
                    Scrollbar(
                      controller: _scrollController,
                      child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        controller: _scrollController,
                        itemCount:
                            getItemsByGenre('KMT', playlistTitles).length,
                        itemBuilder: (BuildContext context, int index) {
                          return StatefulBuilder(builder:
                              (BuildContext context, StateSetter setState) {
                            return ItemSelectionController(
                                child: ItemSelectionBuilder(
                                    index: int.parse(getItemsByGenre(
                                            'KMT', playlistTitles)[index]
                                        .id),
                                    builder: (context, index, selected) {
                                      //if there is a change in _currentSongId then update _selectedIndex
                                      int inferredIndex =
                                          int.parse(_currentSongId.value);
                                      if (inferredIndex != _selectedIndex_kmt) {
                                        _selectedIndex_kmt = inferredIndex;
                                      }
                                      return Card(
                                        elevation: selected ? 2 : 10,
                                        child: ListTile(
                                            onTap: () => {
                                                  pageManager.seekToSong(index),
                                                  setState(() {
                                                    _selectedIndex_kmt = index;
                                                  }),
                                                },
                                            onLongPress: () {
                                              pageManager.seekToSong(index);
                                              setState(() {
                                                _selectedIndex_kmt = index;
                                              });
                                            },
                                            title: _selectedIndex_kmt == index
                                                ? Text(
                                                    '${playlistTitles[index].title}',
                                                    style: TextStyle(
                                                        fontSize: 15,
                                                        color: Colors.green),
                                                  )
                                                : Text(
                                                    '${playlistTitles[index].title}',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      color: Colors
                                                          .purple.shade700,
                                                    ),
                                                  ),
                                            trailing: _selectedIndex_kmt ==
                                                    index
                                                ? Icon(Icons.speaker,
                                                    color:
                                                        Colors.green.shade700)
                                                : Icon(
                                                    Icons.queue_music_rounded,
                                                    color:
                                                        Colors.purple.shade700),
                                            leading: CircleAvatar(
                                              backgroundImage:
                                                  AssetImage('images/kmt.png'),
                                              radius:
                                                  _selectedIndex_kmt == index
                                                      ? 20
                                                      : 9,
                                            ),
                                            tileColor: _selectedIndex_kmt ==
                                                    index
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.purple
                                                    .withOpacity(0.1)),
                                      );
                                    }));
                          });
                        },
                      ),
                    ),
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
        //print('SEEKING....');
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
        Icon icon;
        switch (value) {
          case RepeatState.off:
            icon = Icon(Icons.repeat, color: Colors.white);
            break;
          case RepeatState.repeatSong:
            icon = Icon(Icons.repeat_one, color: Colors.white);
            break;
          case RepeatState.repeatPlaylist:
            icon = Icon(Icons.repeat, color: Colors.white);
            break;
        }
        return IconButton(
            icon: icon, onPressed: pageManager.repeat, color: Colors.white);
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
