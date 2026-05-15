import 'package:vibration/vibration.dart';
import '../storage/local_storage_service.dart';

class VibrationService {
  final LocalStorageService _localStorage;

  VibrationService(this._localStorage);

  Future<void> lightVibrate() async {
    if (_localStorage.isVibrationEnabled) {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 50, amplitude: 64);
      }
    }
  }

  Future<void> heavyVibrate() async {
    if (_localStorage.isVibrationEnabled) {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 150, amplitude: 128);
      }
    }
  }
}
