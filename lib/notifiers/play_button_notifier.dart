import 'package:flutter/foundation.dart';

class PlayButtonNotifier extends ValueNotifier<ButtonState> {
  PlayButtonNotifier() : super(ButtonState.paused);

  void setState(ButtonState newState) {
    if (value == newState) return;
    value = newState; // This automatically notifies listeners
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


enum ButtonState {
  paused,
  playing,
  loading,
}
