import 'package:audioplayers/audioplayers.dart';
import '../storage/local_storage_service.dart';

class AudioService {
  final LocalStorageService _localStorage;
  final AudioPlayer _player = AudioPlayer();

  AudioService(this._localStorage) {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> playSwipeSound() async {
    if (_localStorage.isSoundEnabled) {
      // Assuming you will add 'swipe.wav' to assets/sounds/ later
      // await _player.play(AssetSource('sounds/swipe.wav'));
    }
  }

  Future<void> playMergeSound() async {
    if (_localStorage.isSoundEnabled) {
      // await _player.play(AssetSource('sounds/merge.wav'));
    }
  }

  Future<void> playWinSound() async {
    if (_localStorage.isSoundEnabled) {
      // await _player.play(AssetSource('sounds/win.wav'));
    }
  }
}
