import 'package:flutter/material.dart';
import '../../../services/storage/local_storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final LocalStorageService _localStorage;

  late bool _isSoundEnabled;
  late bool _isVibrationEnabled;

  SettingsProvider(this._localStorage) {
    _isSoundEnabled = _localStorage.isSoundEnabled;
    _isVibrationEnabled = _localStorage.isVibrationEnabled;
  }

  bool get isSoundEnabled => _isSoundEnabled;
  bool get isVibrationEnabled => _isVibrationEnabled;

  Future<void> toggleSound() async {
    _isSoundEnabled = !_isSoundEnabled;
    await _localStorage.setSoundEnabled(_isSoundEnabled);
    notifyListeners();
  }

  Future<void> toggleVibration() async {
    _isVibrationEnabled = !_isVibrationEnabled;
    await _localStorage.setVibrationEnabled(_isVibrationEnabled);
    notifyListeners();
  }
}
