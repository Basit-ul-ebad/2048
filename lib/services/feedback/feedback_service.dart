import '../audio/audio_service.dart';
import '../storage/local_storage_service.dart';
import '../vibration/vibration_service.dart';

/// Game-wide sound + haptics, respecting user settings in [LocalStorageService].
class FeedbackService {
  FeedbackService(LocalStorageService storage)
      : _audio = AudioService(storage),
        _vibration = VibrationService(storage);

  final AudioService _audio;
  final VibrationService _vibration;

  /// Called after a successful tile move.
  void onMove({required int scoreGained}) {
    if (scoreGained > 0) {
      _audio.playMergeSound();
      _vibration.mediumVibrate();
    } else {
      _audio.playSwipeSound();
      _vibration.lightVibrate();
    }
  }

  void onWin() {
    _audio.playWinSound();
    _vibration.heavyVibrate();
  }

  /// Preview when enabling sound in settings.
  void previewSound() {
    _audio.playMergeSound();
  }

  /// Preview when enabling vibration in settings.
  void previewVibration() {
    _vibration.mediumVibrate();
  }
}
