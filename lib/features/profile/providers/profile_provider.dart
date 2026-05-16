import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/nickname_utils.dart';
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
      } else {
        _userProfile = _fallbackProfile(uid);
      }
    } catch (e) {
      debugPrint('Failed to fetch profile: $e');
      _userProfile = _fallbackProfile(uid);
    }

    _isLoading = false;
    notifyListeners();
  }

  UserModel _fallbackProfile(String uid) {
    final authUser = FirebaseAuth.instance.currentUser;
    return UserModel(
      uid: uid,
      nickname: NicknameUtils.displayName(
        authUser?.displayName,
        email: authUser?.email,
      ),
      email: authUser?.email ?? '',
      highestScore: 0,
      currentLevel: 1,
      exp: 0,
      coins: 0,
      rank: 'Bronze',
      wins: 0,
      losses: 0,
      friendsCount: 0,
    );
  }

  void clearProfile() {
    _userProfile = null;
    notifyListeners();
  }
}
