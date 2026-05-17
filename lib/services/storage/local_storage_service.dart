import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyVibrationEnabled = 'vibration_enabled';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  bool get isSoundEnabled => _prefs.getBool(_keySoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool value) async {
    await _prefs.setBool(_keySoundEnabled, value);
  }

  bool get isVibrationEnabled => _prefs.getBool(_keyVibrationEnabled) ?? true;
  Future<void> setVibrationEnabled(bool value) async {
    await _prefs.setBool(_keyVibrationEnabled, value);
  }

  String? get savedBoard => _prefs.getString('saved_board');
  Future<void> setSavedBoard(String boardJson) async {
    await _prefs.setString('saved_board', boardJson);
  }

  int get savedScore => _prefs.getInt('saved_score') ?? 0;
  Future<void> setSavedScore(int score) async {
    await _prefs.setInt('saved_score', score);
  }

  Future<void> clearSavedGame() async {
    await _prefs.remove('saved_board');
    await _prefs.remove('saved_score');
  }
}
