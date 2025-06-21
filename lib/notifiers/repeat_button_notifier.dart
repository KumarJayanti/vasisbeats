import 'package:flutter/foundation.dart';

class RepeatButtonNotifier extends ValueNotifier<RepeatState> {
  RepeatButtonNotifier() : super(RepeatState.off);

  void nextState() {
    value = RepeatState.values[(value.index + 1) % RepeatState.values.length];
  }
  
  // Explicitly implement ValueListenable
  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
  }
  
  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
  }
}

enum RepeatState {
  off,
  repeatSong,
  repeatPlaylist,
}
