import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/firebase/party_service.dart';
import '../../../services/firebase/firestore_service.dart';

class PartyProvider extends ChangeNotifier {
  final PartyService _partyService;
  final FirestoreService _firestoreService;

  String? _roomId;
  Map<String, dynamic>? _roomData;
  Map<String, dynamic>? _hostProfile;
  Map<String, dynamic>? _guestProfile;
  bool _isLoading = false;
  String? _error;
  
  StreamSubscription<DocumentSnapshot>? _roomSubscription;

  PartyProvider(this._partyService, this._firestoreService);

  String? get roomId => _roomId;
  Map<String, dynamic>? get roomData => _roomData;
  Map<String, dynamic>? get hostProfile => _hostProfile;
  Map<String, dynamic>? get guestProfile => _guestProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> createRoom(String hostId) async {
    _setLoading(true);
    _roomId = await _partyService.createRoom(hostId);
    if (_roomId != null) {
      _listenToRoom();
    } else {
      _setError('Failed to create room.');
    }
    _setLoading(false);
  }

  Future<bool> joinRoom(String guestId, String roomCode) async {
    _setLoading(true);
    _roomId = await _partyService.joinRoomWithCode(guestId, roomCode);
    if (_roomId != null) {
      _listenToRoom();
      _setLoading(false);
      return true;
    } else {
      _setError('Invalid room code or room is full.');
      _setLoading(false);
      return false;
    }
  }

  void _listenToRoom() {
    _roomSubscription?.cancel();
    if (_roomId == null) return;

    _roomSubscription = _partyService.streamRoomState(_roomId!).listen((snapshot) async {
      if (snapshot.exists) {
        _roomData = snapshot.data() as Map<String, dynamic>;
        
        // Fetch profiles if needed
        if (_roomData!['hostId'] != null && _hostProfile == null) {
          final doc = await _firestoreService.getUserProfile(_roomData!['hostId']);
          if (doc.exists) _hostProfile = doc.data() as Map<String, dynamic>;
        }
        
        if (_roomData!['guestId'] != null && (_guestProfile == null || _guestProfile!['uid'] != _roomData!['guestId'])) {
          final doc = await _firestoreService.getUserProfile(_roomData!['guestId']);
          if (doc.exists) _guestProfile = doc.data() as Map<String, dynamic>;
        } else if (_roomData!['guestId'] == null) {
          _guestProfile = null;
        }

        notifyListeners();
      } else {
        // Room was deleted
        _roomId = null;
        _roomData = null;
        _hostProfile = null;
        _guestProfile = null;
        _roomSubscription?.cancel();
        notifyListeners();
      }
    });
  }

  Future<void> startMatch() async {
    if (_roomId != null && _roomData?['roomStatus'] == 'ready') {
      await _partyService.updateRoomStatus(_roomId!, 'in_game');
    }
  }

  Future<void> leaveRoom(String userId) async {
    if (_roomId != null && _roomData != null) {
      bool isHost = _roomData!['hostId'] == userId;
      await _partyService.leaveRoom(_roomId!, userId, isHost);
    }
    _roomSubscription?.cancel();
    _roomId = null;
    _roomData = null;
    _hostProfile = null;
    _guestProfile = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    _error = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }
}
