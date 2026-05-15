import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/firebase/firestore_service.dart';

class ShopProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  List<Map<String, dynamic>> _availableSkins = [
    // Local fallback/defaults
    {'id': 'default', 'name': 'Classic', 'price': 0, 'colors': ['#EDC22E', '#CDC1B4']},
    {'id': 'neon', 'name': 'Neon Lights', 'price': 500, 'colors': ['#00FFCC', '#FF00FF']},
    {'id': 'dark', 'name': 'Dark Mode', 'price': 200, 'colors': ['#333333', '#111111']},
  ];
  
  List<String> _ownedSkins = ['default'];
  String _selectedSkin = 'default';

  ShopProvider(this._firestoreService);

  List<Map<String, dynamic>> get availableSkins => _availableSkins;
  List<String> get ownedSkins => _ownedSkins;
  String get selectedSkin => _selectedSkin;

  Future<void> fetchUserSkins(String uid) async {
    try {
      final doc = await _firestoreService.users.doc(uid).collection('user_skins').doc('owned').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _ownedSkins = List<String>.from(data['skins'] ?? ['default']);
        _selectedSkin = data['selected'] ?? 'default';
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching skins: $e');
    }
  }

  Future<bool> buySkin(String uid, String skinId, int price) async {
    if (_ownedSkins.contains(skinId)) return false;

    try {
      final userDoc = await _firestoreService.getUserProfile(uid);
      final coins = (userDoc.data() as Map<String, dynamic>?)?['coins'] as int? ?? 0;

      if (coins >= price) {
        // Deduct coins and add skin
        await _firestoreService.users.doc(uid).update({
          'coins': FieldValue.increment(-price)
        });

        _ownedSkins.add(skinId);
        await _firestoreService.users.doc(uid).collection('user_skins').doc('owned').set({
          'skins': _ownedSkins,
          'selected': skinId
        }, SetOptions(merge: true));

        _selectedSkin = skinId;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error buying skin: $e');
      return false;
    }
  }

  Future<void> equipSkin(String uid, String skinId) async {
    if (_ownedSkins.contains(skinId)) {
      _selectedSkin = skinId;
      await _firestoreService.users.doc(uid).collection('user_skins').doc('owned').set({
        'selected': skinId
      }, SetOptions(merge: true));
      notifyListeners();
    }
  }
}
