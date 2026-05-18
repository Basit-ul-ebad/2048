import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

class PartyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  CollectionReference get partyRooms => _firestore.collection('party_rooms');

  // Generate a 6-character room code
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[_random.nextInt(chars.length)]).join();
  }

  Future<String?> createRoom(String hostId) async {
    try {
      final roomId = _uuid.v4();
      final roomCode = _generateRoomCode();

      await partyRooms.doc(roomId).set({
        'roomCode': roomCode,
        'hostId': hostId,
        'guestId': null,
        'roomStatus': 'waiting', // waiting, ready, in_game, finished
        'createdAt': FieldValue.serverTimestamp(),
      });

      return roomId;
    } catch (e) {
      print('Failed to create room: $e');
      return null;
    }
  }

  Future<String?> joinRoomWithCode(String guestId, String roomCode) async {
    try {
      final snapshot = await partyRooms
          .where('roomCode', isEqualTo: roomCode)
          .where('roomStatus', isEqualTo: 'waiting')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final roomId = snapshot.docs.first.id;
      final roomData = snapshot.docs.first.data() as Map<String, dynamic>;

      if (roomData['hostId'] == guestId) return null; // Can't join own room as guest

      // Update room to ready
      await partyRooms.doc(roomId).update({
        'guestId': guestId,
        'roomStatus': 'ready',
      });

      return roomId;
    } catch (e) {
      print('Failed to join room: $e');
      return null;
    }
  }

  Stream<DocumentSnapshot> streamRoomState(String roomId) {
    return partyRooms.doc(roomId).snapshots();
  }

  Future<void> updateRoomStatus(String roomId, String status) async {
    await partyRooms.doc(roomId).update({'roomStatus': status});
  }

  Future<void> leaveRoom(String roomId, String userId, bool isHost) async {
    try {
      if (isHost) {
        // If host leaves, destroy room
        await partyRooms.doc(roomId).delete();
      } else {
        // If guest leaves, reset room to waiting
        await partyRooms.doc(roomId).update({
          'guestId': null,
          'roomStatus': 'waiting',
        });
      }
    } catch (e) {
      print('Failed to leave room: $e');
    }
  }
}
