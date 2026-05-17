import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../storage/local_storage_service.dart';

class VibrationService {
  VibrationService(this._localStorage);

  final LocalStorageService _localStorage;

  Future<void> lightVibrate() async {
    if (!_localStorage.isVibrationEnabled) return;
    await _vibrate(duration: 45, haptic: HapticFeedback.selectionClick);
  }

  Future<void> mediumVibrate() async {
    if (!_localStorage.isVibrationEnabled) return;
    await _vibrate(duration: 80, haptic: HapticFeedback.mediumImpact);
  }

  Future<void> heavyVibrate() async {
    if (!_localStorage.isVibrationEnabled) return;
    await _vibrate(duration: 140, haptic: HapticFeedback.heavyImpact);
  }

  Future<void> _vibrate({
    required int duration,
    required Future<void> Function() haptic,
  }) async {
    await haptic();

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          final hasAmplitude = await Vibration.hasAmplitudeControl();
          if (hasAmplitude == true) {
            await Vibration.vibrate(
              duration: duration,
              amplitude: (duration * 1.5).clamp(64, 255).toInt(),
            );
          } else {
            await Vibration.vibrate(duration: duration);
          }
        }
      } catch (_) {
        // Plugin failure — haptic above is enough.
      }
    }
  }
}
