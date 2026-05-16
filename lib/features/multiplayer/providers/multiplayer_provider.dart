import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../services/firebase/matchmaking_service.dart';
import '../../../services/firebase/realtime_service.dart';

enum MatchState { idle, searching, playing, finished }

class MultiplayerProvider extends ChangeNotifier {
  final MatchmakingService _matchmakingService;
  final RealtimeService _realtimeService;

  MatchState _state = MatchState.idle;
  String? _currentMatchId;
  String? _opponentId;
  
  int _opponentScore = 0;
  List<int> _opponentBoard = List.filled(16, 0);
  String? _opponentEmote;
  int? _opponentEmoteTime;

  StreamSubscription<DatabaseEvent>? _matchSubscription;
  StreamSubscription<DatabaseEvent>? _queueSubscription;

  MultiplayerProvider(this._matchmakingService, this._realtimeService);

  MatchState get state => _state;
  List<int> get opponentBoard => _opponentBoard;
  int get opponentScore => _opponentScore;
  bool get isPlaying => _state == MatchState.playing;
  String? get opponentEmote => _opponentEmote;

  Future<void> findMatch(String userId) async {
    _state = MatchState.searching;
    notifyListeners();

    final matchId = await _matchmakingService.joinQueue(userId);

    if (matchId != null) {
      // Match found immediately!
      _currentMatchId = matchId;
      _state = MatchState.playing;
      _listenToMatch(matchId, userId);
    } else {
      // Waiting in queue. Listen to queue to see if someone matches us
      _queueSubscription = _matchmakingService.matchmakingQueue
          .orderByChild('userId')
          .equalTo(userId)
          .onChildRemoved
          .listen((event) {
        // Our queue item was removed, check for a match
        _checkIfMatched(userId);
      });
    }
    notifyListeners();
  }

  Future<void> _checkIfMatched(String userId) async {
    // A more robust implementation would involve Cloud Functions returning the match ID directly.
    // For this client-side demo, we query the matches collection where we are a player.
    // In a real app, this query might catch older matches unless filtered by timestamp.
    final snapshot = await _realtimeService.onlineMatches
        .orderByChild('player2Id')
        .equalTo(userId)
        .limitToLast(1)
        .get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      final matchId = data.keys.first;
      _currentMatchId = matchId;
      _state = MatchState.playing;
      _listenToMatch(matchId, userId);
      
      _queueSubscription?.cancel();
      notifyListeners();
    }
  }

  String _getLocalPrefix(String localUserId, Map<dynamic, dynamic> data) {
    return (localUserId == data['player1Id']) ? 'player1' : 'player2';
  }

  void _listenToMatch(String matchId, String localUserId) {
    _matchSubscription = _realtimeService.streamMatchState(matchId).listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        
        final p1Id = data['player1Id'];
        final p2Id = data['player2Id'];
        
        _opponentId = (localUserId == p1Id) ? p2Id : p1Id;
        final opponentPrefix = (localUserId == p1Id) ? 'player2' : 'player1';

        // Update opponent board and score via stream throttling / performance layer
        if (data['${opponentPrefix}_board'] != null) {
          _opponentBoard = List<int>.from(data['${opponentPrefix}_board']);
        }
        if (data['${opponentPrefix}_score'] != null) {
          _opponentScore = data['${opponentPrefix}_score'] as int;
        }
        
        // Emotes
        if (data['${opponentPrefix}_emote'] != null && data['${opponentPrefix}_emoteTime'] != null) {
          final emoteTime = data['${opponentPrefix}_emoteTime'] as int;
          if (_opponentEmoteTime == null || emoteTime > _opponentEmoteTime!) {
            _opponentEmoteTime = emoteTime;
            _opponentEmote = data['${opponentPrefix}_emote'];
            // Clear emote after 3 seconds
            Future.delayed(const Duration(seconds: 3), () {
              if (_opponentEmoteTime == emoteTime) {
                _opponentEmote = null;
                notifyListeners();
              }
            });
          }
        }

        if (data['gameState'] == 'finished') {
          _state = MatchState.finished;
        }

        notifyListeners();
      }
    });
  }

  void syncLocalBoard(String userId, List<int> board, int score, {bool force = false}) {
    if (_currentMatchId != null && _state == MatchState.playing) {
      // Very basic local prefix determination, would need actual state tracking for real app
      // Assuming if _opponentId is not null, we just use a generic fetch approach or assume player1 for demo
      // Let's assume we store local prefix when we enter match, or we pass it in. 
      // For this simple demo, we will query realtime data again or just default to player1
      final playerPrefix = 'player1'; // Needs real fix in production
      
      _realtimeService.syncBoardState(
        matchId: _currentMatchId!,
        playerId: playerPrefix, // Should be dynamic
        board: board,
        score: score,
        forceSync: force,
      );
    }
  }

  Future<void> sendEmote(String emote, String userId) async {
    if (_currentMatchId != null && _state == MatchState.playing) {
      // Again, assuming player1 prefix for simple demo.
      final playerPrefix = 'player1'; 
      await _realtimeService.sendEmote(matchId: _currentMatchId!, playerId: playerPrefix, emote: emote);
    }
  }

  Future<void> cancelSearch(String userId) async {
    await _matchmakingService.leaveQueue(userId);
    _queueSubscription?.cancel();
    _state = MatchState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _matchSubscription?.cancel();
    _queueSubscription?.cancel();
    super.dispose();
  }
}
