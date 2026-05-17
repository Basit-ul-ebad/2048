import 'package:audioplayers/audioplayers.dart';

import '../storage/local_storage_service.dart';

class AudioService {
  AudioService(this._localStorage) {
    _player.setReleaseMode(ReleaseMode.stop);
    _player.setVolume(0.85);
  }

  final LocalStorageService _localStorage;
  final AudioPlayer _player = AudioPlayer();

  Future<void> playSwipeSound() async {
    if (!_localStorage.isSoundEnabled) return;
    await _playAsset('sounds/swipe.wav');
  }

  Future<void> playMergeSound() async {
    if (!_localStorage.isSoundEnabled) return;
    await _playAsset('sounds/merge.wav');
  }

  Future<void> playWinSound() async {
    if (!_localStorage.isSoundEnabled) return;
    await _playAsset('sounds/win.wav');
  }

  Future<void> _playAsset(String path) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(path));
    } catch (_) {
      // Ignore playback errors (e.g. missing asset on hot reload).
    }
  }
}
