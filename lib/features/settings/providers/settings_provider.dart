import 'package:flutter/material.dart';
import '../../../services/storage/local_storage_service.dart';
import '../../../services/analytics/analytics_service.dart';
import '../../ai/models/ai_difficulty.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._localStorage, this._analytics) {
    _isSoundEnabled = _localStorage.isSoundEnabled;
    _isVibrationEnabled = _localStorage.isVibrationEnabled;
    _analyticsEnabled = _localStorage.analyticsEnabled;
    _preferredAiDifficulty = _localStorage.preferredAiDifficulty;
    _aiCoachEnabled = _localStorage.aiCoachEnabled;
  }

  final LocalStorageService _localStorage;
  final AnalyticsService _analytics;

  late bool _isSoundEnabled;
  late bool _isVibrationEnabled;
  late bool _analyticsEnabled;
  late AiDifficulty _preferredAiDifficulty;
  late bool _aiCoachEnabled;

  bool get isSoundEnabled => _isSoundEnabled;
  bool get isVibrationEnabled => _isVibrationEnabled;
  bool get analyticsEnabled => _analyticsEnabled;
  AiDifficulty get preferredAiDifficulty => _preferredAiDifficulty;
  bool get aiCoachEnabled => _aiCoachEnabled;

  Future<void> toggleSound() async {
    _isSoundEnabled = !_isSoundEnabled;
    await _localStorage.setSoundEnabled(_isSoundEnabled);
    await _analytics.logSoundToggled(enabled: _isSoundEnabled);
    notifyListeners();
  }

  Future<void> toggleVibration() async {
    _isVibrationEnabled = !_isVibrationEnabled;
    await _localStorage.setVibrationEnabled(_isVibrationEnabled);
    await _analytics.logVibrationToggled(enabled: _isVibrationEnabled);
    notifyListeners();
  }

  Future<void> toggleAnalytics() async {
    _analyticsEnabled = !_analyticsEnabled;
    await _localStorage.setAnalyticsEnabled(_analyticsEnabled);
    await _analytics.syncCollectionEnabled();
    notifyListeners();
  }

  Future<void> setPreferredAiDifficulty(AiDifficulty difficulty) async {
    _preferredAiDifficulty = difficulty;
    await _localStorage.setPreferredAiDifficulty(difficulty);
    notifyListeners();
  }

  Future<void> toggleAiCoach() async {
    _aiCoachEnabled = !_aiCoachEnabled;
    await _localStorage.setAiCoachEnabled(_aiCoachEnabled);
    await _analytics.logAiCoachToggled(enabled: _aiCoachEnabled);
    notifyListeners();
  }
}
