import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../../../services/firebase/firestore_service.dart';

class ProfileProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  
  UserModel? _userProfile;
  bool _isLoading = false;

  ProfileProvider(this._firestoreService);

  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  Future<void> fetchProfile(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestoreService.getUserProfile(uid);
      if (doc.exists) {
        _userProfile = UserModel.fromDocument(doc);
      }
    } catch (e) {
      print('Failed to fetch profile: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearProfile() {
    _userProfile = null;
    notifyListeners();
  }
}
