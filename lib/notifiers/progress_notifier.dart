import 'package:flutter/foundation.dart';
import '../models/progress_bar_state.dart';

class ProgressNotifier extends ChangeNotifier implements ValueListenable<ProgressBarState> {
  ProgressNotifier() : _state = ProgressBarState(
    current: Duration.zero,
    buffered: Duration.zero,
    total: Duration.zero,
  );

  ProgressBarState _state;

  @override
  ProgressBarState get value => _state;

  void update({
    Duration? current,
    Duration? buffered,
    Duration? total,
  }) {
    _state = ProgressBarState(
      current: current ?? _state.current,
      buffered: buffered ?? _state.buffered,
      total: total ?? _state.total,
    );
    notifyListeners();
  }
  
  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
