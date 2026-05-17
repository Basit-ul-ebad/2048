import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../../../services/firebase/firestore_service.dart';

class ProfileProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  
  UserModel? _userProfile;
  bool _isLoading = false;
  bool _isNewUser = false;

  ProfileProvider(this._firestoreService);

  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isNewUser => _isNewUser;

  Future<void> fetchProfile(String uid) async {
    _isLoading = true;
    _isNewUser = false;
    notifyListeners();

    try {
      final doc = await _firestoreService.getUserProfile(uid);
      if (doc.exists) {
        _userProfile = UserModel.fromDocument(doc);
        _isNewUser = false;
      } else {
        _userProfile = null;
        _isNewUser = true;
      }
    } catch (e) {
      print('Failed to fetch profile: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearProfile() {
    _userProfile = null;
    _isNewUser = false;
    notifyListeners();
  }
}
